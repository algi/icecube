//
//  MBAppDelegate.m
//  IceCube
//
//  Created by Marian Bouček on 14.12.12.
//  Copyright (c) 2012 Marian Bouček. All rights reserved.
//

#import "MBAppDelegate.h"

#import "MBJavaHomeService.h"
#import "MBUserPreferences.h"
#import "MBPreferencesWindowController.h"

@interface MBAppDelegate ()

@property MBPreferencesWindowController *preferencesController;

@end

@implementation MBAppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
	// register default values for Maven and Java
	[[MBUserPreferences standardUserPreferences] setDefaultMavenHome:@"/usr/bin/mvn"];
	
	NSXPCConnection *connection = [[NSXPCConnection alloc] initWithServiceName:@"cz.boucekm.JavaHomeService"];
	[connection setRemoteObjectInterface:[NSXPCInterface interfaceWithProtocol:@protocol(MBJavaHomeService)]];
	[connection resume];
	
	[[connection remoteObjectProxy] findDefaultJavaLocationForVersionwithReply:^(NSString *result) {
		[[MBUserPreferences standardUserPreferences] setDefaultJavaHome:result];
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

@end
