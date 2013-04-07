//
//  MBTaskOutputReaderTests.m
//  IceCube
//
//  Created by Marian Bouček on 01.04.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBTaskOutputReaderTests.h"
#import "MBTaskOutputReader.h"

@implementation MBTaskOutputReaderTests

-(void)testLaunchNonExistingGoal
{
	NSTask *task = [[NSTask alloc] init];
	
	task.launchPath = @"/usr/bin/mvn";
	task.arguments = @[@"nesmysl"]; // neexistující goal
	task.currentDirectoryPath = @"/Users/marian/Documents/Projects/Java/pko";
	
	__block NSInteger count = 0;
	[MBTaskOutputReader launchTask:task withOutputConsumer:^(NSString *line) {
		count++;
	}];
	
	NSInteger expectedCount = 39;
	STAssertEquals(count, expectedCount, @"Pocet radek musi být 39.");
}

@end
