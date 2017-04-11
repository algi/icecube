//
//  MBPreferencesWindowController.m
//  IceCube
//
//  Created by Marian Bouček on 22.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBPreferencesWindowController.h"

#import "MBMavenServiceCallback.h"
#import "MBJavaHomeService.h"
#import "MBMavenService.h"

#import <os/log.h>

// user defaults keys
NSString * const kJavaHomeDefaultsKey = @"JavaLocation";
NSString * const kMavenHomeDefaultsKey = @"MavenLocation";

NSString * const kUseDefaultJavaLocationKey = @"UseDefaultJavaLocation";
NSString * const kUseDefaultMavenLocationKey = @"UseDefaultMavenLocation";

@interface MBPreferencesWindowController () <MBMavenServiceCallback>

@property NSXPCConnection *xpcConnection;
@property BOOL taskRunning;

@end

@implementation MBPreferencesWindowController

- (id)init
{
    return self = [super initWithWindowNibName:@"MBPreferencesWindowController"];
}

-(void)windowDidLoad
{
    self.xpcConnection = [[NSXPCConnection alloc] initWithServiceName:@"cz.boucekm.MavenService"];
    self.xpcConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MBMavenService)];

    self.xpcConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MBMavenServiceCallback)];
    self.xpcConnection.exportedObject = self;

    self.taskRunning = NO;

    [self updateVersionInformation];

    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kMavenHomeDefaultsKey options:0 context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kJavaHomeDefaultsKey options:0 context:nil];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:kMavenHomeDefaultsKey] || [keyPath isEqualToString:kJavaHomeDefaultsKey]) {
        [self updateVersionInformation];
    }
}

#pragma mark - User actions -
- (IBAction)selectMavenLocationDidPress:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];

    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];

    openPanel.directoryURL = [[[NSUserDefaults standardUserDefaults] URLForKey:kMavenHomeDefaultsKey] URLByDeletingLastPathComponent];

    __weak MBPreferencesWindowController *weakSelf = self;
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSArray *selectedURLs = [openPanel URLs];
            [[NSUserDefaults standardUserDefaults] setURL:[selectedURLs firstObject] forKey:kMavenHomeDefaultsKey];

            [weakSelf updateVersionInformation];
        }
    }];
}

- (IBAction)selectJavaLocationDidPress:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];

    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];

    openPanel.directoryURL = [[NSUserDefaults standardUserDefaults] URLForKey:kJavaHomeDefaultsKey];

    __weak MBPreferencesWindowController *weakSelf = self;
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSArray *selectedURLs = [openPanel URLs];
            [[NSUserDefaults standardUserDefaults] setURL:[selectedURLs firstObject] forKey:kJavaHomeDefaultsKey];

            [weakSelf updateVersionInformation];
        }
    }];
}

- (IBAction)useMavenDefaultLocationDidPress:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kMavenHomeDefaultsKey];
}

- (IBAction)useJavaDefaultLocationDidPress:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kJavaHomeDefaultsKey];
}

#pragma mark - MBMavenServiceCallback -
-(void)mavenTaskDidWriteLine:(NSString *)line
{
    if ([line hasPrefix:@"Apache Maven"]) {
        NSArray *components = [line componentsSeparatedByString:@" "];
        NSString *mavenVersionString = components[2];

        self.mavenVersion.stringValue = mavenVersionString;
    }

    if ([line hasPrefix:@"Java version"]) {
        NSString *javaVersionString = [line stringByReplacingOccurrencesOfString:@"Java version: " withString:@""];
        self.javaVersion.stringValue = javaVersionString;
    }
}

#pragma mark - Version info -
-(void)updateVersionInformation
{
    if (self.taskRunning) {
        return;
    }
    self.taskRunning = YES;

    [self.progressIndicator startAnimation:self];
    [self.xpcConnection resume];

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    NSURL *path = [[NSFileManager defaultManager] homeDirectoryForCurrentUser];
    NSString *mavenPath = [prefs stringForKey:kMavenHomeDefaultsKey];
    NSDictionary *environment = @{@"JAVA_HOME": [prefs stringForKey:kJavaHomeDefaultsKey]};

    __weak MBPreferencesWindowController *weakSelf = self;

    [[self.xpcConnection remoteObjectProxy] launchMaven:mavenPath withArguments:@"--version" environment:environment atPath:path withReply:^(BOOL launchSuccessful, NSError *error) {

        MBPreferencesWindowController *strongSelf = weakSelf;

        dispatch_sync(dispatch_get_main_queue(), ^{
            if (!launchSuccessful) {
                strongSelf.javaVersion.stringValue = @"";
                strongSelf.mavenVersion.stringValue = @"";

                os_log_error(OS_LOG_DEFAULT, "Unable to get version of Maven. Reason: %{public}@", error.localizedFailureReason);
            }

            [strongSelf.progressIndicator stopAnimation:strongSelf];

            [self.xpcConnection suspend];
            strongSelf.taskRunning = NO;
        });
    }];
}

-(void)dealloc
{
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:kMavenHomeDefaultsKey];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:kJavaHomeDefaultsKey];

    [self.xpcConnection invalidate];
    self.xpcConnection = nil;
}

@end
