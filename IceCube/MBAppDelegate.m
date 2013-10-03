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

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	// update paths in background
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
		// set default Maven home if needed
		NSString *mavenHome = [[NSUserDefaults standardUserDefaults] objectForKey:@"maven.application.path"];
		if (!mavenHome) {
			[[NSUserDefaults standardUserDefaults] setObject:@"/usr/bin/mvn" forKey:@"maven.application.path"];
		}
		
		// renew JAVA_HOME if needed
		NSString *javaVersion = nil;
		BOOL isUserSpecified = NO;
		
		NSNumber *javaSelectedIndex = [[NSUserDefaults standardUserDefaults] objectForKey:@"java.selected.index"];
		if ([javaSelectedIndex integerValue] == 1) {
			isUserSpecified = YES;
		}
		else if ([javaSelectedIndex integerValue] > 5) {
			// index specifies version of Java (eg 6 = Java 6)
			javaVersion = [javaSelectedIndex stringValue];
		}
		
		if (!isUserSpecified) {
			NSXPCConnection *connection = [[NSXPCConnection alloc] initWithServiceName:@"cz.boucekm.JavaHomeService"];
			connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MBJavaHomeService)];
			
			[connection resume];
			
			[[connection remoteObjectProxy] findJavaLocationForVersion:javaVersion withReply:^(NSString *result) {
				[[NSUserDefaults standardUserDefaults] setObject:result forKey:@"java.home.path"];
				[connection invalidate];
			}];
		}
	});
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return NO;
}

- (IBAction)showPreferences:(id)sender
{
	if (!self.preferencesController) {
		self.preferencesController = [[MBPreferencesWindowController alloc] init];
	}
	
	[[self.preferencesController window] makeKeyAndOrderFront:sender];
}

@end
