//
//  MBAppDelegate.m
//  IceCube
//
//  Created by Marian Bouček on 14.12.12.
//  Copyright (c) 2012 Marian Bouček. All rights reserved.
//

#import "MBAppDelegate.h"

#import "MBMavenOutputParser.h"
#import "NSTask+MBTaskOutputParser.h"

@implementation MBAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	// noop
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (IBAction)showPreferences:(id)sender
{
	[self.preferencesWindow makeKeyAndOrderFront:sender];
}

@end
