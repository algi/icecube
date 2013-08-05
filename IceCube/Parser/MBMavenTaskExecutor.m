//
//  MBMavenTaskExecutioner.m
//  IceCube
//
//  Created by Marian Bouček on 19.07.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBMavenTaskExecutor.h"

#import "NSTask+MBTaskOutputParser.h"
#import "MBMavenOutputParser.h"
#import "MBMavenOutputParserDelegate.h"

#define kMavenApplicationPath @"maven.application.path"

@interface MBMavenTaskExecutor ()

@property NSTask *task;

@end

@implementation MBMavenTaskExecutor

#pragma mark - Task manipulation -
-(void)launchMavenWithArguments:(NSString *)arguments
						 onPath:(NSURL *)path
{
	if ([self.task isRunning]) {
		NSAssert([self isRunning] != false, @"Task is already running!");
		return;
	}
	
	self.task = [[NSTask alloc] init];
	
	// setup task
	NSString *launchPath = [[NSUserDefaults standardUserDefaults] stringForKey:kMavenApplicationPath];
	if (!launchPath) {
		launchPath = @"/usr/bin/mvn";
		[[NSUserDefaults standardUserDefaults] setValue:launchPath forKey:kMavenApplicationPath];
	}
	[self.task setLaunchPath:launchPath];
	
	NSArray *taskArgs = [arguments componentsSeparatedByString:@" "];
	[self.task setArguments:taskArgs];
	
	NSString *directoryPath = [path path];
	[self.task setCurrentDirectoryPath:directoryPath];
	
	// start async with normal priority on new thread
	MBMavenOutputParser *parser = [[MBMavenOutputParser alloc]initWithDelegate:self.executionObserver];
	
	[self.executionObserver task:launchPath willStartWithArguments:arguments onPath:directoryPath];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
		[self.task launchWithTaskOutputBlock:^(NSString *line) {
			[parser parseLine:line];
		}];
	});
}

-(BOOL)isRunning
{
	return [self.task isRunning];
}

-(void)terminate
{
	if ([self.task isRunning]) {
		[self.task terminate];
		[self.executionObserver buildDidEndSuccessfully:NO];
	}
}

@end
