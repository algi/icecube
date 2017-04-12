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
                                         userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Task is already running.", @"Raised by task, when user tries to run same project multiple times.")}];
        [remoteObserver mavenTaskDidFinishSuccessfully:NO error:error];
        return;
    }

    self.task = [[NSTask alloc] init];

    [self.task setLaunchPath:[launchPath stringByExpandingTildeInPath]];
    [self.task setArguments:[argumentString componentsSeparatedByString:@" "]];
    [self.task setEnvironment:environment];
    [self.task setCurrentDirectoryPath:[path path]];

    id pipe = [NSPipe pipe];
    [self.task setStandardOutput:pipe];
    [self.task setStandardError:pipe];

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
        [remoteObserver mavenTaskDidFinishSuccessfully:NO error:err];
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
