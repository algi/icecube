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
                              callback:(void (^)(NSString * _Nonnull, NSString * _Nonnull))callback
{
    NSTask *task = [[NSTask alloc] init];

    task.qualityOfService = NSQualityOfServiceUserInitiated;
    task.launchPath = [launchPath stringByExpandingTildeInPath];
    task.environment = environment;
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
        if ([line hasPrefix:@"Apache Maven "]) {
            NSString *trimmedLine = [line stringByReplacingOccurrencesOfString:@"Apache Maven " withString:@""];
            NSArray *components = [trimmedLine componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceCharacterSet];

            mavenVersion = [components firstObject];
        }

        // Java version: 25.0.2, vendor: Homebrew, runtime: /opt/homebrew/Cellar/openjdk/25.0.2/libexec/openjdk.jdk/Contents/Home
        if ([line hasPrefix:@"Java version: "]) {
            NSString *trimmedLine = [line stringByReplacingOccurrencesOfString:@"Java version: " withString:@""];
            NSArray *components = [trimmedLine componentsSeparatedByString:@","];

            javaVersion = [components firstObject];
        }
    }

    callback(mavenVersion, javaVersion);
}

@end
