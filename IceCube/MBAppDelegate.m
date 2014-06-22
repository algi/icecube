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
	// register default values for Maven and Java
	[[NSProcessInfo processInfo] performActivityWithOptions:NSActivityBackground reason:@"Fetching default JavaHome" usingBlock:^{
		NSXPCConnection *connection = [[NSXPCConnection alloc] initWithServiceName:@"cz.boucekm.JavaHomeService"];
		[connection setRemoteObjectInterface:[NSXPCInterface interfaceWithProtocol:@protocol(MBJavaHomeService)]];
		[connection resume];
		
		id<MBJavaHomeService> remoteProxy = [connection remoteObjectProxy];
		[remoteProxy findDefaultJavaHome:^(NSString *defaultJavaHome, NSError *error) {
			
			if (!defaultJavaHome) {
				[NSApp presentError:error];
				defaultJavaHome = @"/System/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents/Home";
			}
			
			NSDictionary *userDefaults = @{@"maven.home": @"/usr/bin/mvn",
										   @"java.home": defaultJavaHome};
			[[NSUserDefaults standardUserDefaults] registerDefaults:userDefaults];
			
			[connection invalidate];
		}];
	}];
}

- (IBAction)showPreferences:(id)sender
{
	if (!self.preferencesController) {
		self.preferencesController = [[MBPreferencesWindowController alloc] init];
	}
	
	[[self.preferencesController window] makeKeyAndOrderFront:sender];
}

@end
