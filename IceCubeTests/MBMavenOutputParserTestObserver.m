//
//  MBMavenOutputParserTestObserver.m
//  IceCube
//
//  Created by Marian Bouček on 31.03.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBMavenOutputParserTestObserver.h"

@implementation MBMavenOutputParserTestObserver

-(void)task:(NSString *)executable willStartWithArguments:(NSString *)arguments onPath:(NSString *)projectDirectory
{
	// noop
}

-(void)buildDidStartWithTaskList:(NSArray *)taskList
{
	[self.taskList removeAllObjects];
	[self.taskList addObjectsFromArray:taskList];
}

-(void)buildDidEndSuccessfully:(BOOL) result
{
	self.result = result;
}

-(void)projectDidStartWithName:(NSString *)taskName
{
	[self.doneTasks addObject:taskName];
}

-(void)newLineDidRecieve:(NSString *)line
{
	// noop
}

@end
