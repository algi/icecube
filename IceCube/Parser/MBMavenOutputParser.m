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
	kBuildDone,
	kScanIgnoredState
} MBParserState;

// build line prefixes
NSString * const kBuildingPrefix =  @"[INFO] Building ";
NSString * const kInfoLinePrefix =  @"[INFO] ";
NSString * const kEmptyLine = @"[INFO]";
NSString * const kStateSeparatorLinePrefix = @"[INFO] ----";
NSString * const kReactorSummaryLinePrefix = @"[INFO] Reactor Summary:";
NSString * const kBuildSuccessPrefix = @"[INFO] BUILD SUCCESS";
NSString * const kBuildErrorPrefix =   @"[INFO] BUILD FAILURE";
NSString * const kReactorBuildOrder = @"[INFO] Reactor Build Order:";

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
		ignoredLines = 2; // skip "Scanning for projects..." and divider line
		
		delegate = parserDelegate;
	}
	return self;
}

-(void)parseLine:(NSString *)line
{
	[delegate newLineDidRecieve:line];
	
	if (ignoredLines > 0) {
		ignoredLines--;
		return;
	}
	
	switch (state) {
		case kStartState:
		{
			// there is no POM
			if ([line hasPrefix:kBuildErrorPrefix]) {
				[self detectBuildResultFromLine:line];
				state = kScanIgnoredState;
			}
			else {
				ignoredLines = 1; // ignore next divider line
				state = kScanningStartedState;
			}
			
			break;
		}
		case kScanningStartedState:
		{
			if ([line isEqualToString:kEmptyLine]) {
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
			
			NSRange range = [self makeRangeFromLine:line withPrefix:kBuildingPrefix];
			NSString *taskName = [line substringWithRange:range];
			
			[delegate projectDidStartWithName:taskName];
			
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
			[self detectBuildResultFromLine:line];
			break;
		}
		case kScanIgnoredState:
		{
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

-(void)detectBuildResultFromLine:(NSString *)line
{
	if ([line hasPrefix:kBuildSuccessPrefix]) {
		[delegate buildDidEndSuccessfully:YES];
	}
	else if ([line hasPrefix:kBuildErrorPrefix]) {
		[delegate buildDidEndSuccessfully:NO];
	}
}

-(NSRange)makeRangeFromLine:(NSString *)line
				 withPrefix:(NSString *)prefix
{
	NSUInteger lineLenght = [line length];
	NSUInteger prefixLenght = [prefix length];
	
	NSAssert3(lineLenght > prefixLenght, @"lineLenght %lu <= prefixLenght %lu on line: %@", lineLenght, prefixLenght, line);
	
	NSUInteger loc = prefixLenght;
	NSUInteger len = (lineLenght - prefixLenght);
	
	if ([line hasSuffix:@"\n"]) {
		len--;
	}
	
	return NSMakeRange(loc, len);
}

@end
