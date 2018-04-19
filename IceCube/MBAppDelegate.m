//
//  MBAppDelegate.m
//  IceCube
//
//  Created by Marian Bouček on 14.12.12.
//  Copyright (c) 2012 Marian Bouček. All rights reserved.
//

#import "MBAppDelegate.h"

#import "MBServiceProvider.h"
#import "MBJavaHomeService.h"
#import "MBPreferencesWindowController.h"

#import <os/log.h>

@interface MBAppDelegate ()

@property MBPreferencesWindowController *preferencesWindowController;

@end

@implementation MBAppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    // check for test suite flag first
    NSInteger doNotScanForJava = [[NSUserDefaults standardUserDefaults] integerForKey:@"MBDoNotScanForJava"];
    if (doNotScanForJava) {
        os_log_info(OS_LOG_DEFAULT, "Skipping Java home scan (requested by user via defaults).");

        [MBAppDelegate registerUserDefaultsWithJavaHome:nil];
        return;
    }

    // register default values for Maven and Java
    NSXPCConnection *connection = [[NSXPCConnection alloc] initWithServiceName:@"cz.boucekm.JavaHomeService"];
    [connection setRemoteObjectInterface:[NSXPCInterface interfaceWithProtocol:@protocol(MBJavaHomeService)]];
    [connection resume];

    id<MBJavaHomeService> remoteProxy = [connection remoteObjectProxy];
    [remoteProxy findDefaultJavaHome:^(NSString *defaultJavaHome, NSError *error) {

        [MBAppDelegate registerUserDefaultsWithJavaHome:defaultJavaHome];
        [connection invalidate];

        if (!defaultJavaHome) {
            os_log_error(OS_LOG_DEFAULT, "Unable to find Java home. Reason: %{public}@", error.localizedFailureReason);

            dispatch_sync(dispatch_get_main_queue(), ^{
                [NSApp presentError:error];
            });
        }
    }];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    // service provider must be registered only after application is fully initialized
    [NSApp setServicesProvider:[[MBServiceProvider alloc] init]];
}

+ (void)registerUserDefaultsWithJavaHome:(NSString *)javaHome
{
    NSDictionary *defaults = @{kMavenHomeDefaultsKey: @"/usr/share/maven/bin/mvn",
                               kJavaHomeDefaultsKey : javaHome ?: @"/System/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents/Home",
                               kUseDefaultJavaLocationKey: @(YES),
                               kUseDefaultMavenLocationKey: @(YES)};

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

-(IBAction)showPreferencesWindow:(id)sender
{
    if (self.preferencesWindowController == nil) {
        self.preferencesWindowController = [[MBPreferencesWindowController alloc] init];
    }

    [self.preferencesWindowController.window makeKeyAndOrderFront:sender];
}

@end
