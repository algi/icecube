//
//  MBJavaHomeServiceTask.m
//  IceCube
//
//  Created by Marian Bouček on 22.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBJavaHomeServiceTask.h"

#import <os/log.h>
#import "MBErrorDomain.h"

static NSString * const kJavaHomeLaunchPath = @"/usr/libexec/java_home";

@implementation MBJavaHomeServiceTask

- (void)findDefaultJavaHome:(void(^)(NSString *result, NSError *error))reply
{
    // prepare task
    NSTask *task = [[NSTask alloc] init];

    task.qualityOfService = NSQualityOfServiceUserInitiated;
    task.launchPath = kJavaHomeLaunchPath;

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;

    // launch task
    @try {
        [task launch];
        [task waitUntilExit];
    }
    @catch (NSException *exception) {
        os_log_error(OS_LOG_DEFAULT, "Unable to launch task %@. Reason: %{public}@", kJavaHomeLaunchPath, [exception reason]);

        reply(nil, [self unableToFindJavaLocationError:exception.reason]);
        return;
    }

    // process output
    NSData *outputData = [pipe.fileHandleForReading readDataToEndOfFile];
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    NSString *javaPath = [outputString stringByTrimmingCharactersInSet:NSCharacterSet.newlineCharacterSet];

    if (javaPath) {
        reply(javaPath, nil);
    }
    else {
        NSString *failureReason = [NSString stringWithFormat:@"Unable to read output from '%@'.", kJavaHomeLaunchPath];
        reply(nil, [self unableToFindJavaLocationError:failureReason]);
    }
}

- (NSError *)unableToFindJavaLocationError:(NSString *)failureReason
{
    NSString *description = NSLocalizedString(@"Unable to find default Java location",
                                              @"Title for 'Unable to find Java' error dialog.");

    NSString *recovery = NSLocalizedString(@"You need to setup Java home manually in application's Preferences.",
                                           @"Recovery suggestion for error dialog 'Unable to find Java'.");

    NSString *openPreferences = NSLocalizedString(@"Open Preferences", @"Open Preferences button for 'Unable to find Java' error dialog.");
    NSString *cancel = NSLocalizedString(@"Cancel", @"Cancel button for 'Unable to find Java' error dialog.");

    return [NSError errorWithDomain:IceCubeDomain
                               code:kIceCube_unableToFindJavaHomeError
                           userInfo:@{NSLocalizedDescriptionKey: description,
                                      NSLocalizedFailureReasonErrorKey: failureReason,
                                      NSLocalizedRecoverySuggestionErrorKey: recovery,
                                      NSLocalizedRecoveryOptionsErrorKey: @[openPreferences, cancel]
                                      }];
}

@end
