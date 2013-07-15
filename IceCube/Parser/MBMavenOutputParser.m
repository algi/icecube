//
//  MBMavenOutputParser.m
//  IceCube
//
//  Created by Marian Bouček on 31.03.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBMavenOutputParser.h"

typedef enum {
	kStartState,
	kScanningStartedState,
	kScanningEndState,
	kProjectDeclarationStartState,
	kProjectDeclarationEndState,
	kProjectRunningState,
	kBuildDone
} MBParserState;

NSString * const kMavenNotifiactionBuildDidStart = @"MBMavenBuildDidStart";
NSString * const kMavenNotifiactionBuildDidEnd = @"MBMavenBuildDidEnd";
NSString * const kMavenNotifiactionProjectDidStart = @"MBMavenProjectDidStart";

NSString * const kMavenNotifiactionBuildDidStart_taskList = @"taskList";
NSString * const kMavenNotifiactionBuildDidEnd_result = @"result";
NSString * const kMavenNotifiactionProjectDidStart_taskName = @"taskName";

// build line prefixes
NSString * const kBuildingPrefix =  @"[INFO] Building ";
NSString * const kInfoLinePrefix =  @"[INFO] ";
NSString * const kEmptyLinePrefix = @"[INFO]  ";
NSString * const kStateSeparatorLinePrefix = @"[INFO] ----";
NSString * const kReactorSummaryLinePrefix = @"[INFO] Reactor Summary:";
NSString * const kBuildSuccessPrefix = @"[INFO] BUILD SUCCESS";
NSString * const kBuildErrorPrefix =   @"[INFO] BUILD FAILURE";

@interface MBMavenOutputParser () {
	MBParserState state;
	NSMutableArray *taskList;
	NSInteger ignoredLines;
}

@end

@implementation MBMavenOutputParser

-(id)init
{
	if (self = [super init]) {
		state = kStartState;
		taskList = [[NSMutableArray alloc] init];
		ignoredLines = 0;
	}
	return self;
}

-(void)parseLine: (NSString *)line
{	
	switch (state) {
		case kStartState:
		{
			ignoredLines = 3; // first three lines are unimportant, skip them
			state = kScanningStartedState;
			break;
		}
		case kScanningStartedState:
		{
			if (ignoredLines > 0) {
				ignoredLines--;
				return;
			}
			
			if ([line length] <=  [kEmptyLinePrefix length]) {
				state = kScanningEndState;
				return;
			}
			
			NSRange range = NSMakeRange([kInfoLinePrefix length], ([line length] - [kInfoLinePrefix length]));
			NSString *projectName = [line substringWithRange:range];
			[taskList addObject:projectName];
			
			break;
		}
		case kScanningEndState:
		{
			NSDictionary *userInfo= @{kMavenNotifiactionBuildDidStart_taskList: [taskList copy]};
			[[NSNotificationCenter defaultCenter] postNotificationName:kMavenNotifiactionBuildDidStart
																object:nil
															  userInfo:userInfo];
			taskList = nil;
			state = kProjectDeclarationStartState;
			break;
		}
		case kProjectDeclarationStartState:
		{
			if ([line hasPrefix:kReactorSummaryLinePrefix]) {
				state = kBuildDone;
				return;
			}
			
			NSRange range = NSMakeRange([kBuildingPrefix length], ([line length] - [kBuildingPrefix length]));
			NSString *taskName = [line substringWithRange:range];
			
			NSDictionary *userInfo = @{kMavenNotifiactionProjectDidStart_taskName: taskName};
			[[NSNotificationCenter defaultCenter] postNotificationName:kMavenNotifiactionProjectDidStart
																object:nil
															  userInfo:userInfo];
			
			state = kProjectDeclarationEndState;
			break;
		}
		case kProjectDeclarationEndState:
		{
			state = kProjectRunningState;
			break;
		}
		case kProjectRunningState:
		{
			if ([line hasPrefix:kStateSeparatorLinePrefix]) {
				state = kProjectDeclarationStartState;
				return;
			}
			break;
		}
		case kBuildDone:
		{
			if ([line hasPrefix:kBuildSuccessPrefix]) {
				[[NSNotificationCenter defaultCenter] postNotificationName:kMavenNotifiactionBuildDidEnd
																	object:nil
																  userInfo:@{kMavenNotifiactionBuildDidEnd_result: @YES}];
			}
			else if ([line hasPrefix:kBuildErrorPrefix]) {
				[[NSNotificationCenter defaultCenter] postNotificationName:kMavenNotifiactionBuildDidEnd
																	object:nil
																  userInfo:@{kMavenNotifiactionBuildDidEnd_result: @NO}];
			}
			
			// we are in final stage so other lines are ignored
			break;
		}
		default:
		{
			NSAssert(NO, @"MBMavenOutputParser recieved unknown state: '%u' on line '%@'.", state, line);
			break;
		}
	}
}

@end
