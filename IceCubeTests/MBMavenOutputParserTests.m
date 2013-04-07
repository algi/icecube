//
//  MBMavenOutputParserTests.m
//  IceCube
//
//  Created by Marian Bouček on 31.03.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBMavenOutputParserTests.h"

#import "DDFileReader.h"
#import "MBMavenOutputParserTestObserver.h"

@implementation MBMavenOutputParserTests

-(void)testReadErrorLog
{
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *filePath = [testBundle pathForResource:@"errorLog" ofType: @"txt"];
		
	NSMutableArray *taskList = [[NSMutableArray alloc] init];
	NSMutableArray *doneTasks = [[NSMutableArray alloc] init];
	
	MBMavenOutputParserTestObserver *testObserver = [[MBMavenOutputParserTestObserver alloc] init];
	testObserver.taskList = taskList;
	testObserver.doneTasks = doneTasks;
	
	MBMavenOutputParser *parser = [[MBMavenOutputParser alloc] init];
	DDFileReader *reader = [[DDFileReader alloc] initWithFilePath:filePath];
	
	[reader enumerateLinesUsingBlock:^(NSString* line, BOOL* stop) {
		[parser parseLine:line];
	}];
	
	// kontroly výsledků
	STAssertTrue(testObserver.result, @"Build must be successful.");
	
	// kontrola očekávaných tasků
	NSArray *expectedTaskList = @[
		  @"PKO parent",
		  @"Common",
		  @"Business",
		  @"Database",
		  @"Mock",
		  @"Jasper reports",
		  @"Web"];
	STAssertTrue([expectedTaskList isEqualToArray:taskList], @"Expected task list must be the same as produced one.");
	
	// kontrola vykonaných tasků
	NSArray *expectedDoneTasks = @[
		@"PKO parent 1.0-SNAPSHOT",
		@"Common 1.0-SNAPSHOT",
		@"Business 1.0-SNAPSHOT",
		@"Database 1.0-SNAPSHOT",
		@"Mock 1.0-SNAPSHOT",
		@"Jasper reports 1.0-SNAPSHOT",
		@"Web 1.0-SNAPSHOT"];
	STAssertTrue([expectedDoneTasks isEqualToArray:doneTasks], @"Expected done task list must be the same as produced one.");
}

@end
