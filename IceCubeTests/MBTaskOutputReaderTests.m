//
//  MBTaskOutputReaderTests.m
//  IceCube
//
//  Created by Marian Bouček on 01.04.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBTaskOutputReaderTests.h"
#import "MBTaskOutputReader.h"

@interface MBTestCounter : NSObject

@property NSInteger count;

+ (MBTestCounter *)sharedInstance;
- (void) addLine:(NSString *)line;

@end

@implementation MBTestCounter

- (id)init
{
	if (self = [super init]) {
		self.count = 0;
	}
	return self;
}

+ (MBTestCounter *)sharedInstance
{
	static MBTestCounter *sharedInstance = nil;
	if (!sharedInstance) {
		sharedInstance = [[MBTestCounter alloc]init];
	}
	return sharedInstance;
}

- (void) addLine:(NSString *)line
{
	self.count = self.count + 1;
	NSLog(@"[%ld] %@", self.count, line);
}

@end

@implementation MBTaskOutputReaderTests

-(void)testLaunchMaven
{
	NSTask *task = [[NSTask alloc] init];
	
	task.launchPath = @"/usr/bin/mvn";
	task.arguments = @[@"nesmysl"]; // neexistující goal
	task.currentDirectoryPath = @"/Users/marian/Documents/Projects/Java/pko";
	
	[MBTaskOutputReader launchTask:task withOutputConsumer:^(NSString *line) {
		[[MBTestCounter sharedInstance] addLine:line];
	}];
	
	NSInteger count = [[MBTestCounter sharedInstance] count];
	NSInteger expectedCount = 39;
	STAssertEquals(count, expectedCount, @"Pocet radek musi být 39.");
}

@end

