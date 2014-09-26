//
//  MBJavaHomeServiceTask.m
//  IceCube
//
//  Created by Marian Bouček on 22.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBJavaHomeServiceTask.h"

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
        NSLog(@"Unable to launch /usr/libexec/java_home task. Reason is: %@", [exception reason]);

        reply(nil, [self createStandardError]);
        return;
    }

    // proceed output
    __autoreleasing NSString *output = nil;

    if ([self readOutputFromHandle:errorOutputHandle toString:&output]) {
        NSLog(@"Unable to find default Java location. Reason is:\n\n%@", output);

        reply(nil, [self createStandardError]);
        return;
    }

    if ([self readOutputFromHandle:standardOutputHandle toString:&output]) {
        reply(output, nil);
        return;
    }

    // this is serious error
    NSLog(@"Unable to read neither standard nor error output!");
    reply(nil, [self createStandardError]);
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

    *outputString = lineBuffer;

    return [lineBuffer length] > 0;
}

- (NSError *)createStandardError
{
    id userInfo = @{NSLocalizedDescriptionKey: @"Unable to find default Java location.",
                    NSLocalizedRecoverySuggestionErrorKey: @"You need to setup Java home manually in application's Preferences."};
    
    return [NSError errorWithDomain:NSPOSIXErrorDomain
                               code:errno
                           userInfo:userInfo];
}

@end
