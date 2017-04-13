//
//  MBMavenServiceTask.m
//  IceCube
//
//  Created by Marian Bouček on 20.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBMavenServiceTask.h"

#import "MBMavenServiceCallback.h"
#import "MBErrorDomain.h"
#import "MBMavenOutputParser.h"

@interface MBMavenServiceTask () <MBMavenServiceCallback>

@property BOOL result;
@property NSTask *task;

@end

@implementation MBMavenServiceTask

-(void)buildProjectWithMaven:(NSString *)launchPath
                   arguments:(NSString *)arguments
                 environment:(NSDictionary *)environment
            currentDirectory:(NSURL *)currentDirectory
{
    self.result = NO;

    id remoteObserver = [self.xpcConnection remoteObjectProxy];

    if ([self.task isRunning]) {
        NSError *error = [NSError errorWithDomain:IceCubeDomain
                                             code:kIceCube_mavenTaskAlreadyRunningError
                                         userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Task is already running.", @"Raised by task, when user tries to run same project multiple times.")}];
        [remoteObserver mavenTaskDidFinishWithError:error];
        return;
    }

    self.task = [[NSTask alloc] init];

    self.task.launchPath = [launchPath stringByExpandingTildeInPath];
    self.task.arguments = [arguments componentsSeparatedByString:@" "];
    self.task.environment = environment;
    self.task.currentDirectoryPath = [currentDirectory path];

    id pipe = [NSPipe pipe];
    self.task.standardOutput = pipe;
    self.task.standardError = pipe;

    @try {
        [self.task launch];
    }
    @catch (NSException *exception) {
        id err = [NSError errorWithDomain:IceCubeDomain
                                     code:kIceCube_unableToLaunchMavenError
                                 userInfo:@{
                                            NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to run Maven", @"Raised when system cannot launch Maven task. Main title for error dialog 'Unable to run Maven'."),
                                            NSLocalizedFailureReasonErrorKey: exception.reason,
                                            NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Please set correct path to Maven in Preferences.", @"Recovery suggestion text for user, which points him to Preferences in application. It appears in 'Unable to run Maven' error dialog."),
                                            NSLocalizedRecoveryOptionsErrorKey: @[
                                                    NSLocalizedString(@"Open Preferences", @"Button in 'Unable to run Maven' error dialog."),
                                                    NSLocalizedString(@"Cancel", @"Button in 'Unable to run Maven' error dialog.")]
                                            }];
        [remoteObserver mavenTaskDidFinishWithError:err];
        return;
    }

    __weak id weakSelf = self;
    self.task.terminationHandler = ^(NSTask * _Nonnull terminatedTask) {
        MBMavenServiceTask *strongSelf = weakSelf;
        [strongSelf.xpcConnection.remoteObjectProxy mavenTaskDidFinishSuccessfullyWithResult:strongSelf.result];
    };

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [weakSelf readOutputFromPipe:pipe];
    });
}

- (void)terminateBuild
{
    [self.task interrupt];
}

-(void)parseMavenOutput:(NSString *)mavenOutput
{
    id parser = [[MBMavenOutputParser alloc] initWithDelegate:self];

    NSArray<NSString *> *lines = [mavenOutput componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString *line in lines) {
        [parser parseLine:line];
    }

    [self.xpcConnection.remoteObjectProxy mavenTaskDidFinishSuccessfullyWithResult:self.result];
}

#pragma mark - Output handling
-(void)readOutputFromPipe:(NSPipe *)pipe
{
    MBMavenOutputParser *parser = [[MBMavenOutputParser alloc] initWithDelegate:self];

    NSData *inData = nil;
    NSString *partialLinesBuffer = nil;
    NSFileHandle *fileHandle = [pipe fileHandleForReading];
    NSCharacterSet *characterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    while ((inData = [fileHandle availableData]) && [inData length]) {
        NSString *outputLine = [[NSString alloc] initWithData:inData encoding:[NSString defaultCStringEncoding]];
        NSArray *components = [outputLine componentsSeparatedByString:@"\n"];

        if (partialLinesBuffer) {
            // append partial line to the start of buffer
            NSString *firstObject = [components firstObject];
            NSString *fullLine = [partialLinesBuffer stringByAppendingString:firstObject];

            NSMutableArray *mutableCopy = [components mutableCopy];
            [mutableCopy setObject:fullLine atIndexedSubscript:0];

            components = mutableCopy;
            partialLinesBuffer = nil;
        }

        NSInteger linesCount = [components count];

        // if last component doesn't have newline
        // append it to partial line buffer and then skip it
        NSString *lastComponent = [components lastObject];
        if (![lastComponent hasSuffix:@"\n"]) {
            partialLinesBuffer = [lastComponent copy];
            linesCount--;
        }

        NSUInteger index;
        for (index = 0; index < linesCount; index++) {

            NSString *line = [components[index] stringByTrimmingCharactersInSet:characterSet];
            if ([line length] == 0) {
                continue;
            }

            [parser parseLine:line];
        }
    }

    // consume rest of partial lines
    if (partialLinesBuffer) {
        [parser parseLine:partialLinesBuffer];
    }
}

#pragma mark - MBMavenServiceCallback for parser
-(void)mavenTaskDidStartWithTaskList:(NSArray *)taskList
{
    [self.xpcConnection.remoteObjectProxy mavenTaskDidStartWithTaskList:taskList];
}

-(void)mavenTaskDidStartProject:(NSString *)name
{
    [self.xpcConnection.remoteObjectProxy mavenTaskDidStartProject:name];
}

-(void)mavenTaskDidWriteLine:(NSString *)line
{
    [self.xpcConnection.remoteObjectProxy mavenTaskDidWriteLine:line];
}

-(void)mavenTaskDidFinishSuccessfullyWithResult:(BOOL)result
{
    self.result = result;
}

-(void)mavenTaskDidFinishWithError:(NSError *)error
{
    NSAssert(false, @"Unexpected call of method -mavenTaskDidFinishWithError: from parser with error: %@", error);
}

@end
