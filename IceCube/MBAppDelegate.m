//
//  MBAppDelegate.m
//  IceCube
//
//  Created by Marian Bouček on 14.12.12.
//  Copyright (c) 2012 Marian Bouček. All rights reserved.
//

#import "MBAppDelegate.h"

@implementation MBAppDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return NO;
}

- (IBAction)showPreferences:(id)sender
{
	[self.preferencesWindow makeKeyAndOrderFront:sender];
}

@end
