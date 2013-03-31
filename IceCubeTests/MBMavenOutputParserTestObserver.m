//
//  MBMavenOutputParserTestObserver.m
//  IceCube
//
//  Created by Marian Bouček on 31.03.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBMavenOutputParserTestObserver.h"

@implementation MBMavenOutputParserTestObserver

-(id)init
{
	if (self = [super init]) {
		NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
		[defaultCenter addObserver:self selector:@selector(buildDidStart:)   name:kMavenNotifiactionBuildDidStart object:nil];
		[defaultCenter addObserver:self selector:@selector(buildDidEnd:)     name:kMavenNotifiactionBuildDidEnd   object:nil];
		[defaultCenter addObserver:self selector:@selector(projectDidStart:) name:kMavenNotifiactionProjectDidStart object:nil];
	}
	
	return self;
}

-(void)buildDidStart:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];
	NSArray *taskList = [userInfo objectForKey:kMavenNotifiactionBuildDidStart_taskList];
	
	[self.taskList removeAllObjects];
	[self.taskList addObjectsFromArray:taskList];
}

-(void)buildDidEnd:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];
	BOOL result = [userInfo objectForKey:kMavenNotifiactionBuildDidEnd_result];
	self.result = result;
}

-(void)projectDidStart:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];
	NSString *taskName = [userInfo objectForKey:kMavenNotifiactionProjectDidStart_taskName];
	
	[self.doneTasks addObject:taskName];
}

@end
