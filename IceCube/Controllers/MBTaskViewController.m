//
//  MBTaskViewController.m
//  IceCube
//
//  Created by Marian Bouček on 15.07.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBTaskViewController.h"

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
	_running = YES;
	
	// TODO ...
}

-(void)stopTask
{
	[self.currentTask terminate];
	
	self.currentTask = nil;
	_running = NO;
}

@end
