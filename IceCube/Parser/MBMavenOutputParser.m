//
//  MBMavenOutputParser.m
//  IceCube
//
//  Created by Marian Bouček on 31.03.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBMavenOutputParser.h"

#import "MBMavenOutputParserDelegate.h"

typedef NS_ENUM(NSInteger, MBParserState) {
	MBParserStateStart,
	MBParserStateScanningStarted,
	MBParserStateScanningEnd,
	MBParserStateProjectDeclarationStart,
	MBParserStateProjectDeclarationEnd,
	MBParserStateProjectRunning,
	MBParserStateBuildDone,
	MBParserStateScanIgnored
};

// build line prefixes
static NSString * const kInfoLinePrefix           = @"[INFO] ";
static NSString * const kStateSeparatorLinePrefix = @"[INFO] ----";
static NSString * const kBuildingPrefix           = @"[INFO] Building ";
static NSString * const kReactorSummaryLinePrefix = @"[INFO] Reactor Summary:";
static NSString * const kErrorInScanPrefix        = @"[ERROR] Could not find the selected project in the reactor:";

static NSString * const kEmptyLine             = @"[INFO]";
static NSString * const kBuildSuccessLine      = @"[INFO] BUILD SUCCESS";
static NSString * const kBuildErrorLine        = @"[INFO] BUILD FAILURE";
static NSString * const kReactorBuildOrderLine = @"[INFO] Reactor Build Order:";
static NSString * const kScanningStartedLine   = @"[INFO] Scanning for projects...";
static NSString * const kErrorExecutingLine    = @"[ERROR] Error executing Maven.";

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
		state = MBParserStateStart;
		
		_delegate = parserDelegate;
	}
	return self;
}

-(void)parseLine:(NSString *)line
{
	[self.delegate newLineDidRecieve:line];
	
	switch (state) {
		case MBParserStateStart:
		{
			// first line
			if ([line isEqualToString:kScanningStartedLine]) {
				return;
			}
			
			if ([line hasPrefix:kStateSeparatorLinePrefix]) {
				// scanning started
				state = MBParserStateScanningStarted;
				return;
			}
			
			if ([line isEqualToString:kEmptyLine]) {
				// one module only project, scanning is therefore done
				state = MBParserStateScanningEnd;
				return;
			}
			
			if ([line hasPrefix:kErrorInScanPrefix] || [line isEqualToString:kErrorExecutingLine]) {
				// correct goal but incorrect -pl specifier OR there was problem in executing Maven
				[self.delegate buildDidEndSuccessfully:NO];
				state = MBParserStateScanIgnored;
				return;
			}
			
			NSAssert(NO, @"State: 'kStartState', unknown line: %@", line);
			break;
		}
		case MBParserStateScanningStarted:
		{
			if ([line isEqualToString:kReactorBuildOrderLine]) {
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
					state = MBParserStateScanningEnd;
					return;
				}
			}
			
			if ([line isEqualToString:kBuildErrorLine]) {
				// there is an error, so terminate scanning
				[self handleResultOfBuildFromLine:line];
				state = MBParserStateScanIgnored;
				return;
			}
			
			// otherwise extract name of project from line
			NSRange range = [self makeRangeFromLine:line withPrefix:kInfoLinePrefix];
			NSString *projectName = [line substringWithRange:range];
			
			[taskList addObject:projectName];
			break;
		}
		case MBParserStateScanningEnd:
		{
			NSAssert([line hasPrefix:kStateSeparatorLinePrefix], @"State: 'kScanningEndState', unkown line: %@", line);
			
			[self.delegate buildDidStartWithTaskList:[taskList copy]]; // tasklist can be proceeded async, so copy it
			taskList = nil;
			
			state = MBParserStateProjectDeclarationStart;
			break;
		}
		case MBParserStateProjectDeclarationStart:
		{
			if ([line hasPrefix:kReactorSummaryLinePrefix]) {
				// build is done
				state = MBParserStateBuildDone;
				return;
			}
			
			if ([line isEqualToString:kBuildErrorLine] || [line isEqualToString:kBuildSuccessLine]) {
				// handle end of build
				[self handleResultOfBuildFromLine:line];
				state = MBParserStateScanIgnored;
				return;
			}
			
			NSAssert([line hasPrefix:kBuildingPrefix], @"State 'kProjectDeclarationStartState', unknow line: %@", line);
			
			NSRange range = [self makeRangeFromLine:line withPrefix:kBuildingPrefix];
			NSString *taskName = [line substringWithRange:range];
			
			[self.delegate projectDidStartWithName:taskName];
			
			state = MBParserStateProjectDeclarationEnd;
			break;
		}
		case MBParserStateProjectDeclarationEnd:
		{
			NSAssert([line hasPrefix:kStateSeparatorLinePrefix], @"State 'kProjectDeclarationEndState', unknown line: %@", line);
			
			state = MBParserStateProjectRunning;
			break;
		}
		case MBParserStateProjectRunning:
		{
			if ([line hasPrefix:kStateSeparatorLinePrefix]) {
				state = MBParserStateProjectDeclarationStart;
				return;
			}
			break;
		}
		case MBParserStateBuildDone:
		{
			if ([line hasPrefix:@"[INFO] BUILD "]) {
				[self handleResultOfBuildFromLine:line];
				state = MBParserStateScanIgnored;
			}
			else {
				// ignore rest of lines untile BUILD SUCCESS or BUILD FAILURE occurs
			}
			
			break;
		}
		case MBParserStateScanIgnored:
		{
			// we are in final stage so other lines are ignored
			break;
		}
	}
}

#pragma mark - Utilities -
-(void)handleResultOfBuildFromLine:(NSString *)line
{
	if ([line isEqualToString:kBuildSuccessLine]) {
		[self.delegate buildDidEndSuccessfully:YES];
	}
	else if ([line isEqualToString:kBuildErrorLine]) {
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
