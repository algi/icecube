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
NSString * const kScanningStartedLine = @"[INFO] Scanning for projects...";
NSString * const kReactorBuildOrderLine = @"[INFO] Reactor Build Order:";

@interface MBMavenOutputParser () {
	MBParserState state;
	NSMutableArray *taskList;
}

@property(weak) id<MBMavenOutputParserDelegate> delegate;

@end

@implementation MBMavenOutputParser

-(id)initWithDelegate:(id<MBMavenOutputParserDelegate>)parserDelegate
{
	if (self = [super init]) {
		state = kStartState;
		
		_delegate = parserDelegate;
	}
	return self;
}

-(void)parseLine:(NSString *)line
{
	[self.delegate newLineDidRecieve:line];
	
	switch (state) {
		case kStartState:
		{
			// first line
			if ([line isEqualToString:kScanningStartedLine]) {
				return;
			}
			
			if ([line hasPrefix:kStateSeparatorLinePrefix]) {
				// scanning started
				state = kScanningStartedState;
				return;
			}
			
			if ([line isEqualToString:kEmptyLine]) {
				// one module only project, scanning is therefore done
				state = kScanningEndState;
				return;
			}
			
			NSAssert(NO, @"State: 'kStartState', unknown line: %@", line);
			break;
		}
		case kScanningStartedState:
		{
			if ([line isEqualToString:kReactorBuildOrder]) {
				// great, scanning really started
				taskList = [[NSMutableArray alloc] init];
				return;
			}
			
			if ([line isEqualToString:kEmptyLine]) {
				if ([taskList count] == 0) {
					// ok, move on - list of projects will follow
					return;
				}
				else {
					// task list is filled, so we can transfer to next state
					state = kScanningEndState;
					return;
				}
			}
			
			if ([line isEqualToString:kBuildErrorPrefix]) {
				// there is an error, so terminate scanning
				[self handleResultOfBuildFromLine:line];
				state = kScanIgnoredState;
				return;
			}
			
			// otherwise extract name of project from line
			NSRange range = [self makeRangeFromLine:line withPrefix:kInfoLinePrefix];
			NSString *projectName = [line substringWithRange:range];
			
			[taskList addObject:projectName];
			break;
		}
		case kScanningEndState:
		{
			NSAssert([line hasPrefix:kStateSeparatorLinePrefix], @"State: 'kScanningEndState', unkown line: %@", line);
			
			[self.delegate buildDidStartWithTaskList:[taskList copy]]; // tasklist can be proceeded async, so copy it
			taskList = nil;
			
			state = kProjectDeclarationStartState;
			break;
		}
		case kProjectDeclarationStartState:
		{
			if ([line hasPrefix:kReactorSummaryLinePrefix]) {
				// build is done
				state = kBuildDone;
				return;
			}
			
			if ([line isEqualToString:kBuildErrorPrefix] || [line isEqualToString:kBuildSuccessPrefix]) {
				// handle end of build
				[self handleResultOfBuildFromLine:line];
				state = kScanIgnoredState;
				return;
			}
			
			NSAssert([line hasPrefix:kBuildingPrefix], @"State 'kProjectDeclarationStartState', unknow line: %@", line);
			
			NSRange range = [self makeRangeFromLine:line withPrefix:kBuildingPrefix];
			NSString *taskName = [line substringWithRange:range];
			
			[self.delegate projectDidStartWithName:taskName];
			
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
			if ([line hasPrefix:@"[INFO] BUILD "]) {
				[self handleResultOfBuildFromLine:line];
				state = kScanIgnoredState;
			}
			else {
				// ignore rest of lines untile BUILD SUCCESS or BUILD FAILURE occurs
			}
			
			break;
		}
		case kScanIgnoredState:
		{
			// we are in final stage so other lines are ignored
			break;
		}
		default:
		{
			NSAssert(NO, @"Unknown state: '%u' while processing line '%@'.", state, line);
			break;
		}
	}
}

#pragma mark - Utilities -
-(void)handleResultOfBuildFromLine:(NSString *)line
{
	if ([line hasPrefix:kBuildSuccessPrefix]) {
		[self.delegate buildDidEndSuccessfully:YES];
	}
	else if ([line hasPrefix:kBuildErrorPrefix]) {
		[self.delegate buildDidEndSuccessfully:NO];
	}
	else {
		NSAssert(NO, @"State 'kBuildDone', unknown line: %@", line);
	}
}

-(NSRange)makeRangeFromLine:(NSString *)line
				 withPrefix:(NSString *)prefix
{
	NSUInteger lineLenght = [line length];
	NSUInteger prefixLenght = [prefix length];
	
	NSAssert(lineLenght > prefixLenght, @"lineLenght %lu <= prefixLenght %lu on line: %@", lineLenght, prefixLenght, line);
	
	NSUInteger loc = prefixLenght;
	NSUInteger len = (lineLenght - prefixLenght);
	
	if ([line hasSuffix:@"\n"]) {
		len--;
	}
	
	return NSMakeRange(loc, len);
}

@end
