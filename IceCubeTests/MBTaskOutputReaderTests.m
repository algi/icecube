//
//  MBTaskOutputReaderTests.m
//  IceCube
//
//  Created by Marian Bouček on 01.04.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBTaskOutputReaderTests.h"
#import "NSTask+MBTaskOutputParser.h"

@implementation MBTaskOutputReaderTests

-(void)testLaunchNonExistingGoal
{
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *filePath = [testBundle pathForResource:@"build-success" ofType: @"txt"];
	
	NSTask *task = [[NSTask alloc] init];
	
	task.launchPath = @"/bin/cat";
	task.arguments = @[filePath];
	task.currentDirectoryPath = @"/";
	
	__block NSInteger count = 0;
	[task launchWithTaskOutputBlock:^(NSString *line) {
		count++;
	}];
	
	NSInteger expectedCount = 167;
	STAssertEquals(count, expectedCount, @"Expected number of lines is 167.");
}

@end
