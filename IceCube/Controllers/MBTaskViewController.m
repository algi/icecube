//
//  MBTaskViewController.m
//  IceCube
//
//  Created by Marian Bouček on 15.07.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBTaskViewController.h"

#import "MBMavenTaskExecutor.h"

@interface MBTaskViewController ()

@property MBMavenTaskExecutor *executor;

@end

@implementation MBTaskViewController

-(id)init
{
	self = [super init];
	
	if (self) {
		_executor = [[MBMavenTaskExecutor alloc]init];
		// TODO addObservers
	}
	
	return self;
}

-(IBAction)startTask:(id)sender
{
	NSString *args = nil;
	NSURL *path = nil;
	
	[self.executor launchWithArguments:args onPath:path];
}

-(IBAction)stopTask:(id)sender
{
	[self.executor terminate];
}

@end
