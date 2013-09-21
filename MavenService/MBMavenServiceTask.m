//
//  MBMavenServiceTask.m
//  IceCube
//
//  Created by Marian Bouček on 20.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBMavenServiceTask.h"

#import "NSTask+MBTaskOutputParser.h"
#import "MBMavenOutputParser.h"

#import "MBMavenServiceCallback.h"

static NSString * const kMavenApplicationPath = @"maven.application.path";

@interface MBMavenServiceTask ()

@property NSTask *task;

@end

@implementation MBMavenServiceTask

- (void)launchMavenWithArguments:(NSString *)arguments
						  onPath:(NSURL *)path
{
	// in no case is allowed to launch task multiple times!
	BOOL taskIsRunning = self.task != nil;
	if (taskIsRunning) {
		@throw [NSException exceptionWithName:@"TaskAlreadyRunning"
									   reason:@"Task is already running! You must not allow user to call this method second time."
									 userInfo:nil];
		exit(-1);
	}
	
	self.task = [[NSTask alloc] init];
	
	// launch path
	NSError *error = nil;
	NSString *launchPath = [self launchPath:&error];
	if (!launchPath) {
		[[self executionObserver] buildDidEndSuccessfully:NO];
		exit(-1);
	}
	[self.task setLaunchPath:launchPath];
	
	// arguments
	NSArray *taskArgs = [arguments componentsSeparatedByString:@" "];
	[self.task setArguments:taskArgs];
	
	// environment
	NSDictionary *environment = [self environment:&error];
	if (!environment) {
		[[self executionObserver] buildDidEndSuccessfully:NO];
		exit(-1);
	}
	[self.task setEnvironment:environment];
	
	// directory path
	NSString *directoryPath = [path path];
	[self.task setCurrentDirectoryPath:directoryPath];
	
	// start async with normal priority on new thread
	[[self executionObserver] task:launchPath willStartWithArguments:arguments onPath:directoryPath];
	
	MBMavenOutputParser *parser = [[MBMavenOutputParser alloc]initWithDelegate:[self executionObserver]];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
		[self.task launchWithTaskOutputBlock:^(NSString *line) {
			[parser parseLine:line];
		}];
	});
}

- (void)terminateTask
{
	[self.task terminate];
	exit(0);
}

- (id)executionObserver
{
	return [self.xpcConnection remoteObjectProxy];
}

#pragma mark - Task preparation -
- (NSString *)launchPath:(NSError **)error
{
	NSString *launchPath = [[NSUserDefaults standardUserDefaults] stringForKey:kMavenApplicationPath];
	if (!launchPath) {
		launchPath = @"/usr/bin/mvn";
		[[NSUserDefaults standardUserDefaults] setValue:launchPath forKey:kMavenApplicationPath];
	}
	
	if (! [[NSFileManager defaultManager] fileExistsAtPath:launchPath]) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"MBMavenNotFound"
										 code:1
									 userInfo:@{NSLocalizedDescriptionKey: @"Maven not found."}];
		}
		return nil;
	}
	
	return launchPath;
}

- (NSDictionary *)environment:(NSError **)error
{
	NSTask *javaHomeTask = [[NSTask alloc] init];
	[javaHomeTask setLaunchPath:@"/usr/libexec/java_home"];
	
	__block NSString *javaHomeValue = nil;
	[javaHomeTask launchWithTaskOutputBlock:^(NSString *line) {
		if (!javaHomeValue) {
			javaHomeValue = line;
		}
	}];
	
	if (javaHomeValue) {
		return @{@"JAVA_HOME": javaHomeValue};
	}
	else {
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"MBJavaHomeNotFound"
										 code:1
									 userInfo:@{NSLocalizedDescriptionKey: @"Unable to determine JAVA_HOME."}];
		}
		return nil;
	}
}

@end
