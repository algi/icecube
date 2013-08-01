//
//  MBAppDelegate.m
//  IceCube
//
//  Created by Marian Bouček on 14.12.12.
//  Copyright (c) 2012 Marian Bouček. All rights reserved.
//

#import "MBAppDelegate.h"

#import "MBTaskRunnerWindowController.h"

@interface MBAppDelegate ()

@property MBTaskRunnerWindowController *taskRunnerController;

@end

@implementation MBAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	self.taskRunnerController = [[MBTaskRunnerWindowController alloc] init];
	[self.taskRunnerController showWindow:nil];
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
