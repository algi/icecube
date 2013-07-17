//
//  MBTaskViewController.m
//  IceCube
//
//  Created by Marian Bouček on 15.07.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBTaskViewController.h"

#import "NSTask+MBTaskOutputParser.h"

@interface MBTaskViewController ()

@property NSTask *currentTask;

@end

@implementation MBTaskViewController

-(void)startTask
{
	// do not start already running task
	@synchronized(self.currentTask) {
		if (self.currentTask) {
			return;
		}
	}
	
	self.currentTask = [[NSTask alloc] init];
	
	// TODO configure task
	
	// TODO launch task on separate thread
	__weak MBTaskViewController *myself = self;
	[self.currentTask setTerminationHandler:^(NSTask *task) {
		NSLog(@"Task did end.");
		
		myself.currentTask = nil;
	}];
	
	[self.currentTask launchWithCallback:^(NSString *line) {
		NSLog(@"%@", line);
	}];
}

-(void)stopTask
{
	[self.currentTask terminate];
	self.currentTask = nil;
}

@end
