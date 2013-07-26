//
//  MBMavenOutputParserTests.m
//  IceCube
//
//  Created by Marian Bouček on 31.03.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBMavenOutputParserTests.h"

#import "MBTestAdditions.h"
#import "DDFileReader.h"
#import "MBMavenOutputParserTestObserver.h"

@implementation MBMavenOutputParserTests

-(void)testReadBuildSuccess
{
	MBMavenOutputParserTestObserver *observer = [MBMavenOutputParserTests launchedTestObserverForResource:@"build-success"];
	STAssertTrue(observer.result, @"Build must be successful.");
	
	NSArray *expectedTaskList = @[
		  @"PKO parent",
		  @"Common",
		  @"Business",
		  @"Database",
		  @"Mock",
		  @"Jasper reports",
		  @"Web"];
	MBAssertEqualArrays(expectedTaskList, observer.taskList, @"Expected task list must be the same as produced one.");
	
	NSArray *expectedDoneTasks = @[
		@"PKO parent 1.0-SNAPSHOT",
		@"Common 1.0-SNAPSHOT",
		@"Business 1.0-SNAPSHOT",
		@"Database 1.0-SNAPSHOT",
		@"Mock 1.0-SNAPSHOT",
		@"Jasper reports 1.0-SNAPSHOT",
		@"Web 1.0-SNAPSHOT"];
	MBAssertEqualArrays(expectedDoneTasks, observer.doneTasks, @"Expected done task list must be the same as produced one.");
	
	STAssertEquals(observer.lineCount, 166ul, @"Sample has 167 lines (last line is ignored because it is empty).");
	STAssertEquals(observer.buildDidEndCount, 1ul, @"Build must be ended only once.");
	STAssertEquals(observer.buildDidStartCount, 1ul, @"Build must start with task list only once.");
	STAssertEquals(observer.projectDidStartCount, 7ul, @"Build has 7 sub-modules.");
}

-(void)testReadBuildFailureNoPom
{
	MBMavenOutputParserTestObserver *observer = [MBMavenOutputParserTests launchedTestObserverForResource:@"build-failure-no-pom"];
	
	STAssertFalse(observer.result, @"Build must be failure.");
	STAssertTrue([observer.taskList count] == 0, @"Task list must be empty.");
	STAssertTrue([observer.doneTasks count] == 0,  @"Done tasks must be empty.");
	
	STAssertEquals(observer.lineCount, 15ul, @"Sample has 15 lines.");
	STAssertEquals(observer.buildDidEndCount, 1ul, @"Build must be ended only once.");
	STAssertEquals(observer.buildDidStartCount, 0ul, @"Build has no tasks.");
	STAssertEquals(observer.projectDidStartCount, 0ul, @"Build has no sub-modules.");
}

-(void)testReadBuildFailureUnknownPhase
{
	MBMavenOutputParserTestObserver *observer = [MBMavenOutputParserTests launchedTestObserverForResource:@"build-failure-unknown-phase"];
	
	STAssertFalse(observer.result, @"Build must be failure.");
	STAssertTrue([observer.taskList count] == 0, @"Task list must be empty.");
	STAssertTrue([observer.doneTasks count] == 0,  @"Done tasks must be empty.");
	
	// TODO observe and check events
	STAssertEquals(observer.lineCount, 20ul, @"Sample has 20 lines.");
	STAssertEquals(observer.buildDidEndCount, 1ul, @"Build must be ended only once.");
	STAssertEquals(observer.buildDidStartCount, 0ul, @"Build has no tasks.");
	STAssertEquals(observer.projectDidStartCount, 0ul, @"Build has no sub-modules.");
}

#pragma mark - Utility methods -
+(MBMavenOutputParserTestObserver *)launchedTestObserverForResource:(NSString *)resource
{
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *filePath = [testBundle pathForResource:resource ofType: @"txt"];
	
	NSAssert1(filePath != nil, @"Path doesn't exist for resource %@ of type txt.", resource);
	
	MBMavenOutputParserTestObserver *testObserver = [[MBMavenOutputParserTestObserver alloc] init];
	testObserver.taskList = [[NSMutableArray alloc] init];
	testObserver.doneTasks = [[NSMutableArray alloc] init];
	
	MBMavenOutputParser *parser = [[MBMavenOutputParser alloc] initWithDelegate:testObserver];
	DDFileReader *reader = [[DDFileReader alloc] initWithFilePath:filePath];
	
	NSCharacterSet *characterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	[reader enumerateLinesUsingBlock:^(NSString* line, BOOL* stop) {
		NSString *trimmedLine = [line stringByTrimmingCharactersInSet:characterSet];
		[parser parseLine:trimmedLine];
	}];
	
	return testObserver;
}

@end
