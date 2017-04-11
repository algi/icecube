//
//  MBMavenServiceTask.m
//  IceCube
//
//  Created by Marian Bouček on 20.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBMavenServiceTask.h"

#import "MBMavenServiceCallback.h"
#import "NSTask+MBTaskOutputParser.h"
#import "MBErrorDomain.h"

@interface MBMavenServiceTask ()

@property NSTask *task;

@end

@implementation MBMavenServiceTask

- (void)launchMaven:(NSString *)launchPath
      withArguments:(NSString *)arguments
        environment:(NSDictionary *)environment
             atPath:(NSURL *)path
          withReply:(void (^)(BOOL launchSuccessful, NSError *error))reply
{
    if ([self.task isRunning]) {
        NSError *error = [NSError errorWithDomain:IceCubeDomain
                                             code:kIceCube_mavenTaskAlreadyRunningError
                                         userInfo:@{NSLocalizedDescriptionKey: @"Task is already running."}];
        reply(NO, error);
        return;
    }

    self.task = [[NSTask alloc] init];

    [self.task setLaunchPath:launchPath];
    [self.task setArguments:[arguments componentsSeparatedByString:@" "]];
    [self.task setEnvironment:environment];
    [self.task setCurrentDirectoryPath:[path path]];

    NSXPCConnection *xpcConnection = self.xpcConnection;
    id remoteObserver = [xpcConnection remoteObjectProxy];

    id block = ^(NSString *line) {
        [remoteObserver mavenTaskDidWriteLine:line];
    };

    NSError *error = nil;
    BOOL result = [self.task launchTaskWithTaskOutputBlock:block error:&error];
    
    reply(result, error);
}

- (void)terminateTask
{
    [self.task terminate];
}

@end
