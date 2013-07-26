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
	self = [super init];
	if (self) {
		_lineCount = 0;
		_buildDidEndCount = 0;
		_buildDidStartCount = 0;
		_projectDidStartCount = 0;
	}
	return self;
}

-(void)task:(NSString *)executable willStartWithArguments:(NSString *)arguments onPath:(NSString *)projectDirectory
{
	// noop
}

-(void)buildDidStartWithTaskList:(NSArray *)taskList
{
	_buildDidStartCount++;
	
	[self.taskList removeAllObjects];
	[self.taskList addObjectsFromArray:taskList];
}

-(void)buildDidEndSuccessfully:(BOOL) result
{
	_buildDidEndCount++;
	_result = result;
}

-(void)projectDidStartWithName:(NSString *)taskName
{
	_projectDidStartCount++;
	[self.doneTasks addObject:taskName];
}

-(void)newLineDidRecieve:(NSString *)line
{
	_lineCount++;
}

@end
