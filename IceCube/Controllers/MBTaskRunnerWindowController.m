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

#import "MBAppDelegate.h"
#import "MBTaskRunnerDocument.h"
#import "MBPreferencesWindowController.h"

#import "MBErrorDomain.h"

#import <os/log.h>

@interface MBTaskRunnerWindowController () <MBMavenServiceCallback>

@property NSString *uniqueID;

@property BOOL taskRunning;
@property NSProgress *progress;
@property (nonatomic) NSXPCConnection *connection;

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
    self.connection = [[NSXPCConnection alloc] initWithServiceName:@"cz.boucekm.MavenBuildService"];

    self.connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MBMavenService)];
    self.connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MBMavenServiceCallback)];
    self.connection.exportedObject = self;
    [self.connection resume];

    self.window.titlebarAppearsTransparent = YES;
    self.window.movableByWindowBackground = YES;

    // add our button identifiers to default collection, so they will be always visible
    // it's also necessary to add "otherItemsProxy", otherwise it won't work
    // identifiers are declared in XIB, but this property cannot be declared there
    self.touchBar.defaultItemIdentifiers = @[@"RunProject", @"StopProject", NSTouchBarItemIdentifierOtherItemsProxy];
    self.touchBar.customizationAllowedItemIdentifiers = @[@"RunProject", @"StopProject"];
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

#pragma mark - NSRestorableState -
-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];

    NSAttributedString *text = self.outputTextView.textStorage;
    [coder encodeObject:text forKey:@"mb_outputTextView"];
}

-(void)restoreStateWithCoder:(NSCoder *)coder
{
    [super restoreStateWithCoder:coder];

    NSAttributedString *text = [coder decodeObjectForKey:@"mb_outputTextView"];
    if (text) {
        [self.outputTextView.textStorage setAttributedString:text];
    }
}

#pragma mark - NSWindowDelegate -
-(NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self document] undoManager];
}

- (NSRect)window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet usingRect:(NSRect)rect;
{
    return NSMakeRect(rect.origin.x,
                      self.visualEffectView.visibleRect.size.height,
                      rect.size.width,
                      rect.size.height);
}

#pragma mark - IB actions -
- (IBAction)selectCommand:(id)sender
{
    [self.window makeFirstResponder:self.commandField];
}

- (IBAction)selectWorkingDirectory:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];

    openPanel.canChooseFiles = NO;
    openPanel.canChooseDirectories = YES;
    openPanel.allowsMultipleSelection = NO;
    openPanel.directoryURL = [self.document workingDirectory];

    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            NSURL *url = [[openPanel URLs] firstObject];
            [[self document] setWorkingDirectory:url];
        }
    }];
}

- (IBAction)startTask:(id)sender
{
    if (self.taskRunning) {
        [self stopTask:sender];
        return;
    }

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
    self.progress = [NSProgress progressWithTotalUnitCount:1];

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    NSURL *workingDirectory = [[self document] workingDirectory];
    NSString *launchPath = [prefs stringForKey:kMavenHomeDefaultsKey];
    NSDictionary *environment = @{@"JAVA_HOME": [prefs stringForKey:kJavaHomeDefaultsKey]};

    self.outputTextView.string = [NSString stringWithFormat:@"$ %@ %@\n", launchPath, args];

    // launch task
    [[self.connection remoteObjectProxy] buildProjectWithMaven:launchPath
                                                     arguments:args
                                                   environment:environment
                                              currentDirectory:workingDirectory];
}

- (IBAction)stopTask:(id)sender
{
    [[self.connection remoteObjectProxy] terminateBuild];
}

- (IBAction)revealFolderInFinder:(id)sender
{
    NSArray *fileURLs = @[self.pathControl.URL];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:fileURLs];
}

#pragma mark - MBMavenServiceCallback -
-(void)mavenTaskDidStartWithTaskList:(NSArray *)taskList
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        // always go for at least 2 units, so the progress is visible
        self.progress.totalUnitCount = taskList.count + 2;
        self.progress.completedUnitCount = 0;
    });
}

-(void)mavenTaskDidStartProject:(NSString *)name
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.progress.completedUnitCount++;
    });
}

-(void)mavenTaskDidWriteLine:(NSString *)line
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSTextStorage *storage = self.outputTextView.textStorage;
        NSDictionary *attributes = [storage attributesAtIndex:0 effectiveRange:nil];

        [storage beginEditing];
        [storage appendAttributedString:[[NSAttributedString alloc] initWithString:[line stringByAppendingString:@"\n"]
                                                                        attributes:attributes]];
        [storage endEditing];

        [self.outputTextView scrollRangeToVisible:NSMakeRange(self.outputTextView.string.length, 0)];
    });
}

-(void)mavenTaskDidFinishSuccessfullyWithResult:(BOOL)buildSuccessful
{
    __weak id weakSelf = self;
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.soundName = NSUserNotificationDefaultSoundName;

        if (buildSuccessful) {
            notification.title = NSLocalizedString(@"Maven build did suceeded.", @"Notification title for successful build.");
            notification.informativeText = NSLocalizedString(@"Maven build did end successfuly.", @"Notification informative text for successful build.");
        }
        else {
            notification.title = NSLocalizedString(@"Maven build didn't succeed.", @"Notification title for unsuccessful build.");
            notification.informativeText = NSLocalizedString(@"Maven build didn't end successfuly.", @"Notification informative text for unsuccessful build.");
        }

        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];

        [weakSelf taskDidTerminate];
    });
}

-(void)mavenTaskDidFinishWithError:(NSError *)error
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        os_log_error(OS_LOG_DEFAULT, "Unable to launch Maven. Reason: %@", error.localizedFailureReason);
        [NSApp presentError:error modalForWindow:self.window delegate:nil didPresentSelector:nil contextInfo:nil];

        [self taskDidTerminate];
    });
}

-(void)taskDidTerminate
{
    self.progress.completedUnitCount++;
    self.taskRunning = NO;
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
