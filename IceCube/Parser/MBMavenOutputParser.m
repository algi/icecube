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
	
	id<MBMavenOutputParserDelegate> delegate;
}

@end

@implementation MBMavenOutputParser

-(instancetype)initWithDelegate:(id<MBMavenOutputParserDelegate>)parserDelegate
{
	if (self = [super init]) {
		state = kStartState;
		taskList = [[NSMutableArray alloc] init];
		ignoredLines = 0;
		
		delegate = parserDelegate;
	}
	return self;
}

-(void)parseLine:(NSString *)line
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
			
			if ([line hasPrefix:kEmptyLinePrefix]) {
				state = kScanningEndState;
				return;
			}
			
			NSRange range = [self makeRangeFromLine:line withPrefix:kInfoLinePrefix];
			NSString *projectName = [line substringWithRange:range];
			
			[taskList addObject:projectName];
			break;
		}
		case kScanningEndState:
		{
			[delegate buildDidStartWithTaskList:[taskList copy]];
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
			
			if ([delegate respondsToSelector:@selector(projectDidStartWithName:)]) {
				NSRange range = [self makeRangeFromLine:line withPrefix:kBuildingPrefix];
				NSString *taskName = [line substringWithRange:range];
				
				[delegate projectDidStartWithName:taskName];
			}
			
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
				[delegate buildDidEndSuccessfully:YES];
			}
			else if ([line hasPrefix:kBuildErrorPrefix]) {
				[delegate buildDidEndSuccessfully:NO];
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

-(NSRange)makeRangeFromLine:(NSString *)line
				 withPrefix:(NSString *)prefix
{
	NSUInteger loc = [prefix length];
	NSUInteger len = ([line length] - [prefix length]);
	
	if ([line hasSuffix:@"\n"]) {
		len--;
	}
	
	return NSMakeRange(loc, len);
}

@end
