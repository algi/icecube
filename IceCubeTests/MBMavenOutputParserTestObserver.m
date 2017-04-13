//
//  MBMavenOutputParserTestObserver.m
//  IceCube
//
//  Created by Marian Bouček on 31.03.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBMavenOutputParserTestObserver.h"

#import "MBMavenOutputParser.h"

@implementation MBMavenOutputParserTestObserver

- (id)init
{
    self = [super init];
    if (self) {
        _result = -1;
        _lineCount = 0;
        _buildDidEndCount = 0;
        _buildDidStartCount = 0;
        _projectDidStartCount = 0;
    }
    return self;
}

-(void)mavenTaskDidStartWithTaskList:(NSArray *)taskList
{
    _buildDidStartCount++;

    [self.taskList removeAllObjects];
    [self.taskList addObjectsFromArray:taskList];
}

-(void)mavenTaskDidStartProject:(NSString *)taskName
{
    _projectDidStartCount++;
    [self.doneTasks addObject:taskName];
}

-(void)mavenTaskDidWriteLine:(NSString *)line
{
    _lineCount++;
}

-(void)mavenTaskDidFinishSuccessfullyWithResult:(BOOL)result
{
    _buildDidEndCount++;
    _result = result;
}

-(void)mavenTaskDidFinishWithError:(NSError *)error
{
    NSAssert(false, @"Unexpected call of method -mavenTaskDidFinishWithError: with error: %@", error);
}

@end
