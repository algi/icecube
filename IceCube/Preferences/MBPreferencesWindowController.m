//
//  MBPreferencesWindowController.m
//  IceCube
//
//  Created by Marian Bouček on 22.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBPreferencesWindowController.h"

#import "MBMavenVersionService.h"

#import <os/log.h>

// user defaults keys
NSString * const kJavaHomeDefaultsKey = @"JavaLocation";
NSString * const kMavenHomeDefaultsKey = @"MavenLocation";

NSString * const kUseDefaultJavaLocationKey = @"UseDefaultJavaLocation";
NSString * const kUseDefaultMavenLocationKey = @"UseDefaultMavenLocation";

@interface MBPreferencesWindowController ()

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
    self.xpcConnection = [[NSXPCConnection alloc] initWithServiceName:@"cz.boucekm.MavenVersionService"];

    self.xpcConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MBMavenVersionService)];
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
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
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
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
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

#pragma mark - Version info -
-(void)updateVersionInformation
{
    if (self.taskRunning) {
        return;
    }

    self.taskRunning = YES;
    [self.progressIndicator startAnimation:self];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSString *launchPath = [defaults stringForKey:kMavenHomeDefaultsKey];
    NSDictionary *environment = @{@"JAVA_HOME": [defaults stringForKey:kJavaHomeDefaultsKey]};

    [self.xpcConnection resume];
    [[self.xpcConnection remoteObjectProxy] readVersionInformationWithMaven:launchPath
                                                                environment:environment
                                                                   callback:^(NSString *mavenVersion, NSString *javaVersion) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.mavenVersion.stringValue = mavenVersion;
            self.javaVersion.stringValue = javaVersion;

            [self.progressIndicator stopAnimation:self];
            [self.xpcConnection suspend];
            self.taskRunning = NO;
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
