//
//  MBTaskViewController.m
//  IceCube
//
//  Created by Marian Bouček on 15.07.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBTaskRunnerWindowController.h"

#import "MBMavenService.h"
#import "MBMavenServiceCallback.h"

#import "MBMavenOutputParser.h"
#import "MBMavenParserDelegate.h"

#import "MBAppDelegate.h"
#import "MBTaskRunnerDocument.h"
#import "MBPreferencesWindowController.h"

#import "MBErrorDomain.h"

#import <os/log.h>

@interface MBTaskRunnerWindowController () <MBMavenServiceCallback, MBMavenParserDelegate>

@property (nonatomic) NSXPCConnection *connection;
@property (nonatomic) MBMavenOutputParser *parser;
@property BOOL taskRunning;

@property NSString *uniqueID;

@end

@implementation MBTaskRunnerWindowController

- (id)init
{
    self = [super initWithWindowNibName:@"MBTaskRunnerDocument"];
    if (self) {
        _uniqueID = [[NSUUID UUID] UUIDString];
    }
    return self;
}

- (void)windowDidLoad
{
    self.parser = [[MBMavenOutputParser alloc] initWithDelegate:self];

    self.connection = [[NSXPCConnection alloc] initWithServiceName:@"cz.boucekm.MavenService"];
    self.connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MBMavenService)];
    self.connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MBMavenServiceCallback)];
    self.connection.exportedObject = self;
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ([menuItem action] == @selector(startTask:)) {
        return !self.taskRunning;
    }

    if ([menuItem action] == @selector(stopTask:)) {
        return self.taskRunning;
    }

    return YES;
}

#pragma mark - NSWindowDelegate -
-(NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self document] undoManager];
}

#pragma mark - IB actions -
- (IBAction)selectCommand:(id)sender
{
    [self.window makeFirstResponder:self.commandField];
}

- (IBAction)selectWorkingDirectory:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];

    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setDirectoryURL:[self.document workingDirectory]];

    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *url = [[openPanel URLs] firstObject];
            [[self document] setWorkingDirectory:url];
        }
    }];
}

- (IBAction)startTask:(id)sender
{
    if (self.taskRunning) {
        return;
    }

    [self.parser resetParser];

    // create Maven execution environment
    NSString *args = [[self document] command];
    if ([args length] == 0) {
        NSString *title = NSLocalizedString(@"Maven error",
                                            @"Maven execution error.");

        NSString *suggestion = NSLocalizedString(@"Unable to build project with empty command.",
                                                 @"User tries to build project with empty command.");

        NSError *error = [NSError errorWithDomain:IceCubeDomain
                                             code:kIceCube_documentEmptyMavenCommandError
                                         userInfo:@{NSLocalizedDescriptionKey: title,
                                                    NSLocalizedRecoverySuggestionErrorKey:suggestion}];

        [NSApp presentError:error modalForWindow:self.window delegate:nil didPresentSelector:nil contextInfo:nil];
        return;
    }

    // prepare UI
    self.taskRunning = YES;
    [self.progressIndicator setIndeterminate:YES];
    [self.progressIndicator startAnimation:self];

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    NSURL *path = [[self document] workingDirectory];
    NSString *mavenPath = [prefs stringForKey:kMavenHomeDefaultsKey];
    NSDictionary *environment = @{@"JAVA_HOME": [prefs stringForKey:kJavaHomeDefaultsKey]};

    [self.outputTextView setString:[NSString stringWithFormat:@"$ %@ %@\n\n", mavenPath, args]];

    // launch task
    [self.connection resume];
    [[self.connection remoteObjectProxy] launchMaven:mavenPath withArguments:args environment:environment atPath:path];
}

- (IBAction)stopTask:(id)sender
{
    [[self.connection remoteObjectProxy] terminateTask];
}

- (IBAction)revealFolderInFinder:(id)sender
{
    NSArray *fileURLs = @[self.pathControl.URL];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:fileURLs];
}

#pragma mark - MBMavenServiceCallback -
- (void)mavenTaskDidWriteLine:(NSString *)line
{
    [self.parser parseLine:line];
}

-(void)mavenTaskDidFinishSuccessfully:(BOOL)launchSuccessful error:(NSError *)error
{
    dispatch_sync(dispatch_get_main_queue(), ^{

        if (! launchSuccessful) {
            os_log_error(OS_LOG_DEFAULT, "Unable to launch Maven. Reason: %@", error.localizedFailureReason);
            [NSApp presentError:error modalForWindow:self.window delegate:nil didPresentSelector:nil contextInfo:nil];
        }

        [self.progressIndicator setDoubleValue:[self.progressIndicator doubleValue] + 1];
        [self.progressIndicator stopAnimation:nil];

        [self.connection suspend];
        self.taskRunning = NO;
    });
}

#pragma mark - MBMavenParserDelegate -
- (void)buildDidStartWithTaskList:(NSArray *)taskList
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressIndicator setMinValue:0];
        [self.progressIndicator setMaxValue:[taskList count] + 1];
        [self.progressIndicator setDoubleValue:0];

        [self.progressIndicator setIndeterminate:NO];
    });
}

- (void)projectDidStartWithName:(NSString *)name
{
    dispatch_async(dispatch_get_main_queue(), ^{
        double doubleValue = [self.progressIndicator doubleValue] + 1;
        [self.progressIndicator setDoubleValue:doubleValue];
    });
}

- (void)buildDidEndSuccessfully:(BOOL)buildWasSuccessful
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressIndicator setDoubleValue:[self.progressIndicator doubleValue] + 1];

        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.soundName = NSUserNotificationDefaultSoundName;

        if (buildWasSuccessful) {
            notification.title = NSLocalizedString(@"Maven build did suceeded.", @"Notification title for successful build.");
            notification.informativeText = NSLocalizedString(@"Maven build did end successfuly.", @"Notification informative text for successful build.");
        }
        else {
            notification.title = NSLocalizedString(@"Maven build didn't succeed.", @"Notification title for unsuccessful build.");
            notification.informativeText = NSLocalizedString(@"Maven build didn't end successfuly.", @"Notification informative text for unsuccessful build.");
        }

        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    });
}

- (void)newLineDidRecieve:(NSString *)line
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTextStorage *storage = [self.outputTextView textStorage];
        NSDictionary *attributes = [storage attributesAtIndex:0 effectiveRange:nil];

        [storage beginEditing];
        [storage appendAttributedString:[[NSAttributedString alloc] initWithString:[line stringByAppendingString:@"\n"]
                                                                        attributes:attributes]];
        [storage endEditing];

        [self.outputTextView scrollRangeToVisible:NSMakeRange([[self.outputTextView string] length], 0)];
    });
}

#pragma mark - Scripting support -
- (NSUniqueIDSpecifier *)objectSpecifier
{
    NSScriptClassDescription *appDescription = (NSScriptClassDescription *)[NSApp classDescription];
    return [[NSUniqueIDSpecifier alloc] initWithContainerClassDescription:appDescription
                                                       containerSpecifier:nil
                                                                      key:@"projects"
                                                                 uniqueID:self.uniqueID];
}

- (NSString *)command
{
    return [[self document] command];
}

- (void)setCommand:(NSString *)command
{
    [[self document] setCommand:command];
}

- (NSURL *)workingDirectory
{
    return [[self document] workingDirectory];
}

- (void)setWorkingDirectory:(NSURL *)workingDirectory
{
    [[self document] setWorkingDirectory:workingDirectory];
}

- (void)handleRunProject:(NSScriptCommand *)command
{
    [self startTask:command];
}

- (void)handleStopProject:(NSScriptCommand *)command
{
    [self stopTask:command];
}

#pragma mark - Dealloc -
- (void)dealloc
{
    [self.connection suspend];
    [self.connection invalidate];
    self.connection = nil;

    self.outputTextView = nil;
}

@end
