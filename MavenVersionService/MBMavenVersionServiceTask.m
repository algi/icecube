//
//  MavenVersionService.m
//  MavenVersionService
//
//  Created by Marian Bouček on 13.04.17.
//  Copyright © 2017 Marian Bouček. All rights reserved.
//

#import "MBMavenVersionServiceTask.h"

@implementation MBMavenVersionServiceTask

-(void)readVersionInformationWithMaven:(NSString *)launchPath
                           environment:(NSDictionary *)environment
                      currentDirectory:(NSURL *)currentDirectory
                              callback:(void (^)(NSString * _Nonnull, NSString * _Nonnull))callback
{
    NSTask *task = [[NSTask alloc] init];

    task.launchPath = [launchPath stringByExpandingTildeInPath];
    task.environment = environment;
    task.currentDirectoryPath = [currentDirectory path];
    task.arguments = @[ @"--version" ];

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;

    @try {
        [task launch];
        [task waitUntilExit];
    }
    @catch (NSException *exception) {
        callback(@"", @"");
        return;
    }

    NSString *mavenVersion = @"";
    NSString *javaVersion = @"";

    NSData *outputData = [pipe.fileHandleForReading readDataToEndOfFile];
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    NSArray<NSString *> *lines = [outputString componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet];

    for (NSString *line in lines) {

        // Apache Maven 3.3.3 (7994120775791599e205a5524ec3e0dfe41d4a06; 2015-04-22T12:57:37+01:00)
        if ([line hasPrefix:@"Apache Maven"]) {
            NSArray *components = [line componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
            mavenVersion = components[2];
        }

        if ([line hasPrefix:@"Java version: "]) {
            javaVersion = [line stringByReplacingOccurrencesOfString:@"Java version: " withString:@""];
        }
    }

    callback(mavenVersion, javaVersion);
}

@end
