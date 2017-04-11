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

@interface MBMavenServiceTask ()

@property NSTask *task;

@end

@implementation MBMavenServiceTask

- (void)launchMaven:(NSString *)launchPath
      withArguments:(NSString *)argumentString
        environment:(NSDictionary *)environment
             atPath:(NSURL *)path
{
    NSXPCConnection *xpcConnection = self.xpcConnection;
    id remoteObserver = [xpcConnection remoteObjectProxy];

    if ([self.task isRunning]) {
        NSError *error = [NSError errorWithDomain:IceCubeDomain
                                             code:kIceCube_mavenTaskAlreadyRunningError
                                         userInfo:@{NSLocalizedDescriptionKey: @"Task is already running."}];
        [remoteObserver mavenTaskDidFinishSuccessfully:NO error:error];
        return;
    }

    NSMutableArray *arguments = [[NSMutableArray alloc] init];
    [arguments addObject:[launchPath stringByExpandingTildeInPath]];
    [arguments addObjectsFromArray:[argumentString componentsSeparatedByString:@" "]];

    self.task = [[NSTask alloc] init];

    [self.task setLaunchPath:@"/bin/bash"];
    [self.task setArguments:arguments];
    [self.task setEnvironment:environment];
    [self.task setCurrentDirectoryPath:[path path]];

    id pipe = [NSPipe pipe];
    [self.task setStandardOutput:pipe];
    [self.task setStandardError:pipe];

    @try {
        [self.task launch];
    }
    @catch (NSException *exception) {
        NSError *error = [NSError errorWithDomain:IceCubeDomain
                                     code:kIceCube_unableToLaunchMavenError
                                 userInfo:@{
                                            NSLocalizedDescriptionKey: @"Unable to run Maven",
                                            NSLocalizedRecoverySuggestionErrorKey: @"Please set correct path to Maven in Preferences.",
                                            NSLocalizedFailureReasonErrorKey: exception.reason
                                            }];
        [remoteObserver mavenTaskDidFinishSuccessfully:NO error:error];
        return;
    }

    self.task.terminationHandler = ^(NSTask * _Nonnull terminatedTask) {
        [remoteObserver mavenTaskDidFinishSuccessfully:YES error:nil];
    };

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        readOutputFromPipeWithObserver(pipe, remoteObserver);
    });
}

- (void)terminateTask
{
    [self.task interrupt];
}

#pragma mark - Output handling -
void readOutputFromPipeWithObserver(NSPipe *pipe, id remoteObserver)
{
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

            [remoteObserver mavenTaskDidWriteLine:line];
        }
    }

    // consume rest of partial lines
    if (partialLinesBuffer) {
        [remoteObserver mavenTaskDidWriteLine:partialLinesBuffer];
    }
}

@end
