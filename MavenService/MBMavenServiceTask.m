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

static NSString * const kMavenApplicationPath = @"maven.application.path";
static NSString * const kJavaHomePath = @"java.home.path";

@interface MBMavenServiceTask ()

@property NSTask *task;

@end

@implementation MBMavenServiceTask

- (void)launchMavenWithArguments:(NSString *)arguments
						  onPath:(NSURL *)path
					   withReply:(void (^)(BOOL launchSuccessful, NSError *error))reply
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
	NSError *mvnError;
	NSString *launchPath = [self launchPath:&mvnError];
	if (!launchPath) {
		reply(NO, mvnError);
		exit(-1);
	}
	[self.task setLaunchPath:launchPath];
	
	// arguments
	NSArray *taskArgs = [arguments componentsSeparatedByString:@" "];
	[self.task setArguments:taskArgs];
	
	// environment
	NSError *envError;
	NSDictionary *environment = [self environment:&envError];
	if (!environment) {
		reply(NO, envError);
		exit(-1);
	}
	[self.task setEnvironment:environment];
	
	// directory path
	NSString *directoryPath = [path path];
	[self.task setCurrentDirectoryPath:directoryPath];
	
	// termination handler
	self.task.terminationHandler = ^(NSTask *task){
		exit(0);
	};
	
	// start async with normal priority on new thread
	NSXPCConnection *xpcConnection = _xpcConnection;
	id observer = [xpcConnection remoteObjectProxy];
	
	// TODO is it really necessary to call dispatch_async? we are async task anyway ;-)
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
		[self.task launchWithTaskOutputBlock:^(NSString *line) {
			[observer mavenTaskDidWriteLine:line];
		}];
	});
	
	// task launched
	reply(YES, nil);
}

- (void)terminateTask
{
	[self.task terminate];
	exit(0);
}

#pragma mark - Task preparation -

// TODO those methods really shouldn't be here - namely 'java_home' task should be separated to its XPC bundle

- (NSString *)launchPath:(__autoreleasing NSError **)error
{
	NSString *launchPath = [[NSUserDefaults standardUserDefaults] stringForKey:kMavenApplicationPath];
	if (launchPath) {
		if ([self isPathAccessible:launchPath]) {
			return launchPath;
		}
		else {
			if (error != NULL) {
				*error = [NSError errorWithDomain:@"MBMavenNotFound"
											 code:1
										 userInfo:@{NSLocalizedDescriptionKey: @"Maven path is not accesible."}];
			}
			return nil;
		}
	}
	
	NSString *defaultLaunchPath = @"/usr/bin/mvn";
	if ([self isPathAccessible:defaultLaunchPath]) {
		return defaultLaunchPath;
	}
	else {
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"MBMavenNotFound"
										 code:2
									 userInfo:@{NSLocalizedDescriptionKey: @"Maven not found."}];
		}
		return nil;
	}
}

- (NSDictionary *)environment:(__autoreleasing NSError **)error
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
		if ([self isPathAccessible:javaHomeValue]) {
			return @{@"JAVA_HOME": javaHomeValue};
		}
		else {
			if (error != NULL) {
				*error = [NSError errorWithDomain:@"MBJavaHomeNotFound"
											 code:1
										 userInfo:@{NSLocalizedDescriptionKey: @"JAVA_HOME is not accesible."}];
			}
			return nil;
		}
	}
	else {
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"MBJavaHomeNotFound"
										 code:2
									 userInfo:@{NSLocalizedDescriptionKey: @"Unable to determine JAVA_HOME."}];
		}
		return nil;
	}
}

- (BOOL)isPathAccessible:(NSString *)path
{
	return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

@end
