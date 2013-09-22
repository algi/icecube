//
//  MBAppDelegate.m
//  IceCube
//
//  Created by Marian Bouček on 14.12.12.
//  Copyright (c) 2012 Marian Bouček. All rights reserved.
//

#import "MBAppDelegate.h"

#import "MBPreferencesWindowController.h"

@interface MBAppDelegate ()

@property MBPreferencesWindowController *preferencesController;

@end

@implementation MBAppDelegate

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
