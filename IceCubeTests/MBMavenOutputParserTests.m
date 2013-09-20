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
#import "MBMavenOutputParser.h"
#import "MBMavenOutputParserTestObserver.h"

@implementation MBMavenOutputParserTests

-(void)testBuildSuccess
{
	MBMavenOutputParserTestObserver *observer = [MBMavenOutputParserTests launchedTestObserverForResource:@"build-success"];
	XCTAssertEqual(observer.result, 1ul, @"Build must be successful.");
	
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
	
	XCTAssertEqual(observer.lineCount, 166ul, @"Sample has 167 lines (last line is ignored because it is empty).");
	XCTAssertEqual(observer.buildDidEndCount, 1ul, @"Build must be ended only once.");
	XCTAssertEqual(observer.buildDidStartCount, 1ul, @"Build must start with task list only once.");
	XCTAssertEqual(observer.projectDidStartCount, 7ul, @"Build has 7 sub-modules.");
}

-(void)testBuildSuccessOneModule
{
	MBMavenOutputParserTestObserver *observer = [MBMavenOutputParserTests launchedTestObserverForResource:@"build-success-one-module"];
	
	XCTAssertEqual(observer.result, 1ul, @"Build must be successful.");
	XCTAssertEqual([observer.taskList count], 0ul, @"Task list must be empty.");
	MBAssertEqualArrays(observer.doneTasks, @[@"Common 1.0-SNAPSHOT"], @"Done tasks must have only one item: 'Common 1.0-SNAPSHOT'");
	
	XCTAssertEqual(observer.lineCount, 31ul, @"Sample has 32 lines (last one is empty so must be omited).");
	XCTAssertEqual(observer.buildDidEndCount, 1ul, @"Build must be ended only once.");
	XCTAssertEqual(observer.buildDidStartCount, 1ul, @"Build has one task.");
	XCTAssertEqual(observer.projectDidStartCount, 1ul, @"Build has one project.");
}

-(void)testBuildFailureNoPom
{
	MBMavenOutputParserTestObserver *observer = [MBMavenOutputParserTests launchedTestObserverForResource:@"build-failure-no-pom"];
	
	XCTAssertEqual(observer.result, 0ul, @"Build must be failure.");
	XCTAssertEqual([observer.taskList count], 0ul, @"Task list must be empty.");
	XCTAssertEqual([observer.doneTasks count], 0ul,  @"Done tasks must be empty.");
	
	XCTAssertEqual(observer.lineCount, 15ul, @"Sample has 15 lines.");
	XCTAssertEqual(observer.buildDidEndCount, 1ul, @"Build must be ended only once.");
	XCTAssertEqual(observer.buildDidStartCount, 0ul, @"Build has no tasks.");
	XCTAssertEqual(observer.projectDidStartCount, 0ul, @"Build has no sub-modules.");
}

-(void)testBuildFailureNoProject
{
	MBMavenOutputParserTestObserver *observer = [MBMavenOutputParserTests launchedTestObserverForResource:@"build-failure-no-project"];
	XCTAssertEqual(observer.result, 0ul, @"Build must be failure.");
	XCTAssertEqual([observer.taskList count], 0ul, @"Task list must be empty.");
	XCTAssertEqual([observer.doneTasks count], 0ul,  @"Done tasks must be empty.");
	
	XCTAssertEqual(observer.lineCount, 8ul, @"Sample has 9 lines (last one is empty so must be omited).");
	XCTAssertEqual(observer.buildDidEndCount, 1ul, @"Build must be ended only once.");
	XCTAssertEqual(observer.buildDidStartCount, 0ul, @"Build has no tasks.");
	XCTAssertEqual(observer.projectDidStartCount, 0ul, @"Build has no sub-modules.");
}

-(void)testBuildFailureNonParsable
{
	MBMavenOutputParserTestObserver *observer = [MBMavenOutputParserTests launchedTestObserverForResource:@"build-failure-non-parsable"];
	XCTAssertEqual(observer.result, 0ul, @"Build must be failure.");
	XCTAssertEqual([observer.taskList count], 0ul, @"Task list must be empty.");
	XCTAssertEqual([observer.doneTasks count], 0ul,  @"Done tasks must be empty.");
	
	XCTAssertEqual(observer.lineCount, 3ul, @"Sample has 4 lines (last one is empty so must be omited).");
	XCTAssertEqual(observer.buildDidEndCount, 1ul, @"Build must be ended only once.");
	XCTAssertEqual(observer.buildDidStartCount, 0ul, @"Build has no tasks.");
	XCTAssertEqual(observer.projectDidStartCount, 0ul, @"Build has no sub-modules.");
}

-(void)testBuildFailureUnknownPhase
{
	MBMavenOutputParserTestObserver *observer = [MBMavenOutputParserTests launchedTestObserverForResource:@"build-failure-unknown-phase"];
	
	XCTAssertEqual(observer.result, 0ul, @"Build must be failure.");
	XCTAssertEqual([observer.taskList count], 0ul, @"Task list must be empty.");
	MBAssertEqualArrays(observer.doneTasks, @[@"Common 1.0-SNAPSHOT"], @"Done tasks must have only one item: 'Common 1.0-SNAPSHOT'");
	
	XCTAssertEqual(observer.lineCount, 19ul, @"Sample has 20 lines (last one is empty so must be omited).");
	XCTAssertEqual(observer.buildDidEndCount, 1ul, @"Build must be ended only once.");
	XCTAssertEqual(observer.buildDidStartCount, 1ul, @"Build started one task.");
	XCTAssertEqual(observer.projectDidStartCount, 1ul, @"Build has one project.");
}

-(void)testBuildFailureNoJavaHome
{
	MBMavenOutputParserTestObserver *observer = [MBMavenOutputParserTests launchedTestObserverForResource:@"build-failure-no-java_home"];
	XCTAssertEqual(observer.result, 0ul, @"Build must be failure.");
	XCTAssertEqual([observer.taskList count], 0ul, @"Task list must be empty.");
	XCTAssertEqual([observer.doneTasks count], 0ul,  @"Done tasks must be empty.");
	
	XCTAssertEqual(observer.lineCount, 2ul, @"Sample has 3 lines (last one is empty so must be omited).");
	XCTAssertEqual(observer.buildDidEndCount, 1ul, @"Build must be ended only once.");
	XCTAssertEqual(observer.buildDidStartCount, 0ul, @"Build has no tasks.");
	XCTAssertEqual(observer.projectDidStartCount, 0ul, @"Build has no sub-modules.");
}

#pragma mark - Utility methods -
+(MBMavenOutputParserTestObserver *)launchedTestObserverForResource:(NSString *)resource
{
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *filePath = [testBundle pathForResource:resource ofType: @"txt"];
	
	NSAssert(filePath, @"Path doesn't exist for resource %@ of type txt.", resource);
	
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
