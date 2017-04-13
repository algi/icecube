//
//  MBMavenOutputParser.m
//  IceCube
//
//  Created by Marian Bouček on 31.03.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBMavenOutputParser.h"

#import "MBMavenParserDelegate.h"

typedef NS_ENUM(NSInteger, MBParserState) {
    kStateStart,
    kStateScanningStarted,
    kStateScanningEnd,
    kStateProjectDeclarationStart,
    kStateProjectDeclarationEnd,
    kStateProjectRunning,
    kStateBuildDone,
    kStateScanIgnored
};

// build line prefixes
static NSString * const kInfoLinePrefix           = @"[INFO] ";
static NSString * const kStateSeparatorLinePrefix = @"[INFO] ----";
static NSString * const kBuildingPrefix           = @"[INFO] Building ";
static NSString * const kReactorSummaryLinePrefix = @"[INFO] Reactor Summary:";
static NSString * const kErrorInScanPrefix        = @"[ERROR] Could not find the selected project in the reactor:";

static NSString * const kEmptyLine               = @"[INFO]";
static NSString * const kBuildSuccessLine        = @"[INFO] BUILD SUCCESS";
static NSString * const kBuildErrorLine          = @"[INFO] BUILD FAILURE";
static NSString * const kReactorBuildOrderLine   = @"[INFO] Reactor Build Order:";
static NSString * const kScanningStartedLine     = @"[INFO] Scanning for projects...";
static NSString * const kErrorExecutingLine      = @"[ERROR] Error executing Maven.";
static NSString * const kErrorJavaHomeNotSetLine = @"Error: JAVA_HOME is not defined correctly.";

@interface MBMavenOutputParser ()

@property (nonatomic) NSMutableArray *taskList;
@property (assign, nonatomic) MBParserState state;
@property (weak, nonatomic) id<MBMavenParserDelegate> delegate;

@end

@implementation MBMavenOutputParser

- (id)initWithDelegate:(id<MBMavenParserDelegate>)parserDelegate
{
    self = [super init];
    if (self) {
        _delegate = parserDelegate;
        _state = kStateStart;
    }
    return self;
}

- (void)parseLine:(NSString *)line
{
    id<MBMavenParserDelegate> delegate = self.delegate;
    [delegate newLineDidRecieve:line];

    switch (self.state) {
        case kStateStart:
        {
            if ([line isEqualToString:kScanningStartedLine]) {
                // first line
                return;
            }

            if ([line hasPrefix:kStateSeparatorLinePrefix]) {
                // scanning started
                self.state = kStateScanningStarted;
                return;
            }

            if ([line isEqualToString:kEmptyLine]) {
                // one module only project, scanning is therefore done
                self.state = kStateScanningEnd;
                return;
            }

            if ([line hasPrefix:kErrorInScanPrefix] ||
                [line isEqualToString:kErrorExecutingLine] ||
                [line isEqualToString:kErrorJavaHomeNotSetLine])
            {
                // correct goal but incorrect -pl specifier OR there was problem in executing Maven
                [delegate buildDidEndSuccessfully:NO];
                self.state = kStateScanIgnored;
                return;
            }

            NSAssert(NO, @"State: 'kStartState', unknown line: %@", line);
            break;
        }
        case kStateScanningStarted:
        {
            if ([line isEqualToString:kReactorBuildOrderLine]) {
                // great, scanning really started
                self.taskList = [[NSMutableArray alloc] init];
                return;
            }

            if ([line isEqualToString:kEmptyLine]) {
                if ([self.taskList count] == 0) {
                    // ok, move on - list of projects will follow
                    return;
                }
                else {
                    // task list is filled, so we can transfer to next state
                    self.state = kStateScanningEnd;
                    return;
                }
            }

            if ([line isEqualToString:kBuildErrorLine]) {
                // there is an error, so terminate scanning
                [self handleResultOfBuildFromLine:line];

                self.state = kStateScanIgnored;
                return;
            }

            // otherwise extract name of project from line
            NSRange range = [self makeRangeFromLine:line withPrefix:kInfoLinePrefix];
            NSString *projectName = [line substringWithRange:range];

            [self.taskList addObject:projectName];
            break;
        }
        case kStateScanningEnd:
        {
            NSAssert([line hasPrefix:kStateSeparatorLinePrefix], @"State: 'kScanningEndState', unkown line: %@", line);

            [delegate buildDidStartWithTaskList:[self.taskList copy]]; // tasklist can be proceeded async, so copy it

            self.taskList = nil;
            self.state = kStateProjectDeclarationStart;

            break;
        }
        case kStateProjectDeclarationStart:
        {
            if ([line hasPrefix:kReactorSummaryLinePrefix]) {
                // build is done
                self.state = kStateBuildDone;
                return;
            }

            if ([line isEqualToString:kBuildErrorLine] || [line isEqualToString:kBuildSuccessLine]) {
                // handle end of build
                [self handleResultOfBuildFromLine:line];

                self.state = kStateScanIgnored;
                return;
            }

            NSAssert([line hasPrefix:kBuildingPrefix], @"State 'kProjectDeclarationStartState', unknow line: %@", line);

            NSRange range = [self makeRangeFromLine:line withPrefix:kBuildingPrefix];
            NSString *taskName = [line substringWithRange:range];

            [delegate projectDidStartWithName:taskName];

            self.state = kStateProjectDeclarationEnd;
            break;
        }
        case kStateProjectDeclarationEnd:
        {
            NSAssert([line hasPrefix:kStateSeparatorLinePrefix], @"State 'kProjectDeclarationEndState', unknown line: %@", line);

            self.state = kStateProjectRunning;
            break;
        }
        case kStateProjectRunning:
        {
            if ([line hasPrefix:kStateSeparatorLinePrefix]) {
                self.state = kStateProjectDeclarationStart;
                return;
            }
            break;
        }
        case kStateBuildDone:
        {
            if ([line hasPrefix:@"[INFO] BUILD "]) {
                [self handleResultOfBuildFromLine:line];
                self.state = kStateScanIgnored;
            }
            else {
                // ignore rest of lines untile BUILD SUCCESS or BUILD FAILURE occurs
            }
            
            break;
        }
        case kStateScanIgnored:
        {
            // we are in final stage so other lines are ignored
            break;
        }
    }
}

#pragma mark - Utilities -
- (void)handleResultOfBuildFromLine:(NSString *)line
{
    id<MBMavenParserDelegate> delegate = self.delegate;
    if ([line isEqualToString:kBuildSuccessLine]) {
        [delegate buildDidEndSuccessfully:YES];
    }
    else if ([line isEqualToString:kBuildErrorLine]) {
        [delegate buildDidEndSuccessfully:NO];
    }
    else {
        NSAssert(NO, @"State 'kBuildDone', unknown line: %@", line);
    }
}

- (NSRange)makeRangeFromLine:(NSString *)line
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
