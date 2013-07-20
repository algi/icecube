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

#define kMavenApplicationPath @"maven.application.path"

@interface MBMavenTaskExecutor () <MBMavenOutputParserDelegate> {
	dispatch_queue_t main_queue;
}

@property NSTask *task;
@property NSMutableArray *executionObservers;

@end

@implementation MBMavenTaskExecutor

-(id)init
{
	self = [super init];
	
	if (self) {
		main_queue = dispatch_get_main_queue();
		
		_task = [[NSTask alloc] init];
		_executionObservers = [[NSMutableArray alloc] init];
	}
	
	return self;
}

-(void)addExecutionObserver:(id<MBMavenOutputParserDelegate>)observer
{
	[self.executionObservers addObject:observer];
}

-(void)removeExecutionObserver:(id<MBMavenOutputParserDelegate>)observer
{
	[self.executionObservers removeObject:observer];
}

#pragma mark - Task manipulation -
-(void)launchMavenWithArguments:(NSString *)arguments
						 onPath:(NSURL *)path
{
	if ([self isRunning]) {
		NSAssert(false, @"Task is already running!");
		return;
	}
	
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
	
	// start async with normal priority
	__weak id<MBMavenOutputParserDelegate> delegate = self;
	MBMavenOutputParser *parser = [[MBMavenOutputParser alloc]initWithDelegate:delegate];
	
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
	[self.task terminate];
	[self buildDidEndSuccessfully:NO];
}

#pragma mark - MBMavenOutputParserDelegate methods -
-(void)buildDidStartWithTaskList:(NSArray *)taskList
{
	for (id observer in self.executionObservers) {
		dispatch_async(main_queue, ^{
			[observer buildDidStartWithTaskList:taskList];
		});
	}
}

-(void)buildDidEndSuccessfully:(BOOL)result
{
	for (id observer in self.executionObservers) {
		dispatch_async(main_queue, ^{
			[observer buildDidEndSuccessfully:result];
		});
	}
}

-(void)projectDidStartWithName:(NSString *)name
{
	for (id observer in self.executionObservers) {
		dispatch_async(main_queue, ^{
			[observer projectDidStartWithName:name];
		});
	}
}

-(void)newLineDidRecieve:(NSString *)line
{
	for (id observer in self.executionObservers) {
		dispatch_async(main_queue, ^{
			[observer newLineDidRecieve:line];
		});
	}
}

@end
