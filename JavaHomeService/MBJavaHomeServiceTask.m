//
//  MBJavaHomeServiceTask.m
//  IceCube
//
//  Created by Marian Bouček on 22.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBJavaHomeServiceTask.h"

#import "MBErrorDomain.h"
#import <os/log.h>

@implementation MBJavaHomeServiceTask

- (void)findDefaultJavaHome:(void(^)(NSString *result, NSError *error))reply
{
    // prepare task
    NSTask *task = [[NSTask alloc] init];

    [task setLaunchPath:@"/usr/libexec/java_home"];
    [task setArguments:@[@"--task", @"CommandLine"]];

    NSPipe *standardOutputPipe = [NSPipe pipe];
    [task setStandardOutput:standardOutputPipe];

    NSPipe *errorOutputPipe = [NSPipe pipe];
    [task setStandardError:errorOutputPipe];

    NSFileHandle *standardOutputHandle = [standardOutputPipe fileHandleForReading];
    NSFileHandle *errorOutputHandle = [errorOutputPipe fileHandleForReading];

    // launch task
    @try {
        [task launch];
    }
    @catch (NSException *exception) {
        os_log_error(OS_LOG_DEFAULT, "Unable to launch task /usr/libexec/java_home. Reason: %{public}@", [exception reason]);

        reply(nil, [self unableToFindJavaLocationError]);
        return;
    }

    // proceed output
    __autoreleasing NSString *output = nil;

    if ([self readOutputFromHandle:errorOutputHandle toString:&output]) {
        os_log_error(OS_LOG_DEFAULT, "Unable to find default Java location. Reason: %{public}@", output);

        reply(nil, [self unableToFindJavaLocationError]);
        return;
    }

    if ([self readOutputFromHandle:standardOutputHandle toString:&output]) {
        reply(output, nil);
        return;
    }

    // this is serious error
    os_log_fault(OS_LOG_DEFAULT, "Unable to read standard and error output.");
    reply(nil, [self unableToFindJavaLocationError]);
}

- (BOOL)readOutputFromHandle:(NSFileHandle *)outputHandle toString:(NSString * __autoreleasing *)outputString
{
    NSData *inData = nil;
    NSMutableString *lineBuffer = [[NSMutableString alloc] init];

    while ((inData = [outputHandle availableData]) && [inData length]) {

        NSString *rawLine = [[NSString alloc] initWithData:inData encoding:[NSString defaultCStringEncoding]];
        NSString *outputLine = [rawLine stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];

        if ([outputLine isEqualToString:@""]) {
            continue;
        }

        [lineBuffer appendString:outputLine];
        [lineBuffer appendString:@"\n"];
    }

    // remove trailing newline character
    if ([lineBuffer hasSuffix:@"\n"]) {
        NSRange range = NSMakeRange([lineBuffer length] - 1, 1);
        [lineBuffer replaceCharactersInRange:range withString:@""];
    }

    *outputString = lineBuffer;

    return [lineBuffer length] > 0;
}

- (NSError *)unableToFindJavaLocationError
{
    id userInfo = @{NSLocalizedDescriptionKey: @"Unable to find default Java location.",
                    NSLocalizedRecoverySuggestionErrorKey: @"You need to setup Java home manually in application's Preferences."};
    
    return [NSError errorWithDomain:IceCubeDomain
                               code:kIceCube_unableToFindJavaHomeError
                           userInfo:userInfo];
}

@end
