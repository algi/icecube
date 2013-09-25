//
//  MBMavenServiceTask.m
//  IceCube
//
//  Created by Marian Bouček on 20.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBMavenServiceTask.h"

#import "MBMavenServiceCallback.h"
#import "NSTask+MBTaskOutputParser.h"

@interface MBMavenServiceTask ()

@property NSTask *task;

@end

@implementation MBMavenServiceTask

- (void)launchMaven:(NSString *)launchPath
	  withArguments:(NSString *)arguments
		environment:(NSDictionary *)environment
			 atPath:(NSURL *)path
		  withReply:(void (^)(BOOL launchSuccessful, NSError *error))reply
{
	// in no case is allowed to launch task multiple times!
	if (self.task != nil) {
		NSError *error = [NSError errorWithDomain:@"MBTaskLaunchError"
											 code:1
										 userInfo:@{NSLocalizedDescriptionKey: @"Task is already running."}];
		reply(NO, error);
		exit(-1);
	}
	
	self.task = [[NSTask alloc] init];
	
	[self.task setLaunchPath:launchPath];
	[self.task setArguments:[arguments componentsSeparatedByString:@" "]];
	[self.task setEnvironment:environment];
	[self.task setCurrentDirectoryPath:[path path]];
	
	// termination handler
	self.task.terminationHandler = ^(NSTask *task){
		exit(0);
	};
	
	// start async with normal priority on new thread
	NSXPCConnection *xpcConnection = self.xpcConnection;
	id observer = [xpcConnection remoteObjectProxy];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
		
		NSError *error;
		id block = ^(NSString *line) {
			// TODO should be also called async?
			[observer mavenTaskDidWriteLine:line];
		};
		
		BOOL result = [self.task launchWithTaskOutputBlock:block error:error];
		if (!result) {
			reply(NO, error);
		}
	});
	
	// task launched successfuly
	reply(YES, nil);
}

- (void)terminateTask
{
	[self.task terminate];
	exit(0);
}

@end
