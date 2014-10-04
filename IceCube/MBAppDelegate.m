//
//  MBAppDelegate.m
//  IceCube
//
//  Created by Marian Bouček on 14.12.12.
//  Copyright (c) 2012 Marian Bouček. All rights reserved.
//

#import "MBAppDelegate.h"

#import "MBJavaHomeService.h"
#import "MBPreferencesWindowController.h"

@interface MBAppDelegate ()

@property MBPreferencesWindowController *preferencesController;

@end

@implementation MBAppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    // check for test suite flag first
    NSInteger testSuiteFlag = [[NSUserDefaults standardUserDefaults] integerForKey:@"MBDoNotScanForJava"];
    if (testSuiteFlag) {
        NSLog(@"Application will not perform scan for Java home.");

        [MBAppDelegate registerUserDefaultsWithJavaHome:nil];
        return;
    }

    // register default values for Maven and Java
    NSXPCConnection *connection = [[NSXPCConnection alloc] initWithServiceName:@"cz.boucekm.JavaHomeService"];
    [connection setRemoteObjectInterface:[NSXPCInterface interfaceWithProtocol:@protocol(MBJavaHomeService)]];
    [connection resume];

    id<MBJavaHomeService> remoteProxy = [connection remoteObjectProxy];
    [remoteProxy findDefaultJavaHome:^(NSString *defaultJavaHome, NSError *error) {

        if (!defaultJavaHome) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [NSApp presentError:error];
            });
        }

        [MBAppDelegate registerUserDefaultsWithJavaHome:defaultJavaHome];
        [connection invalidate];
    }];
}

- (IBAction)showPreferences:(id)sender
{
    if (!self.preferencesController) {
        self.preferencesController = [[MBPreferencesWindowController alloc] init];
    }

    [[self.preferencesController window] makeKeyAndOrderFront:sender];
}

+ (void)registerUserDefaultsWithJavaHome:(NSString *)javaHome
{
    NSString *defaultMavenHome = @"/usr/bin/mvn";

    NSString *defaultJavaHome = javaHome;
    if (!defaultJavaHome) {
        defaultJavaHome = @"/System/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents/Home";
    }

    NSDictionary *userDefaults = @{kMavenHomeDefaultsKey: defaultMavenHome,
                                   kJavaHomeDefaultsKey : defaultJavaHome,
                                   kUseDefaultJavaLocationKey: @(YES),
                                   kUseDefaultMavenLocationKey: @(YES)};

    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaults];
}

@end
