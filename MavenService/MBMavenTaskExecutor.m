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
#import "MBMavenServiceCallback.h"

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
	
	// launch path
	NSError *error;
	NSString *launchPath = [self launchPath:&error];
	if (!launchPath) {
		// TODO [NSApp presentError:error]; - fuuuuuuuu!!!!!
		return;
	}
	[self.task setLaunchPath:launchPath];
	
	// arguments
	NSArray *taskArgs = [arguments componentsSeparatedByString:@" "];
	[self.task setArguments:taskArgs];
	
	// environment
	NSDictionary *environment = [self environment];
	[self.task setEnvironment:environment];
	
	// directory path
	NSString *directoryPath = [path path];
	[self.task setCurrentDirectoryPath:directoryPath];
	
	// start async with normal priority on new thread
	[self.executionObserver task:launchPath willStartWithArguments:arguments onPath:directoryPath];
	
	MBMavenOutputParser *parser = [[MBMavenOutputParser alloc]initWithDelegate:self.executionObserver];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
		[self.task launchWithTaskOutputBlock:^(NSString *line) {
			[parser parseLine:line];
		}];
	});
}

- (BOOL)isRunning
{
	return [self.task isRunning];
}

- (void)terminate
{
	if ([self.task isRunning]) {
		[self.task terminate];
		[self.executionObserver buildDidEndSuccessfully:NO];
	}
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
			*error = [NSError errorWithDomain:@"" code:1 userInfo:nil]; // TODO ...
		}
		return nil;
	}
	
	return launchPath;
}

- (NSDictionary *)environment
{
	NSTask *javaHomeTask = [[NSTask alloc] init];
	[javaHomeTask setLaunchPath:@"/usr/libexec/java_home"];
	
	__block NSString *javaHomeValue = nil;
	[javaHomeTask launchWithTaskOutputBlock:^(NSString *line) {
		if (!javaHomeValue) {
			javaHomeValue = line;
		}
	}];
	
	NSAssert(javaHomeValue, @"Unable to obtain JAVA_HOME value.");
	return @{@"JAVA_HOME": javaHomeValue};
}

@end
