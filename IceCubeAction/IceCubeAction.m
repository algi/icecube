//
//  IceCubeAction.m
//  IceCubeAction
//
//  Created by Marian Bouček on 03.04.17.
//  Copyright © 2017 Marian Bouček. All rights reserved.
//

#import "IceCubeAction.h"

@implementation IceCubeAction

static NSString * const kDefaultMavenCommand = @"clean install";
static NSString * const kDefaultMavenPath = @"/usr/share/maven/bin/mvn";

-(id)runWithInput:(id)input error:(NSError * _Nullable __autoreleasing *)error
{
    // Maven command
    NSString *mavenCommand = self.parameters[@"mavenCommand"];
    if (mavenCommand == nil) {
        mavenCommand = kDefaultMavenCommand;

        [self logMessageWithLevel:AMLogLevelInfo
                           format:@"Nebyl zadán příkaz pro Maven, bude použit výchozí příkaz: %@", kDefaultMavenCommand];
    }

    // Maven path
    NSString *mavenPath = self.parameters[@"mavenPath"];
    if (mavenPath == nil) {
        mavenPath = kDefaultMavenPath;

        [self logMessageWithLevel:AMLogLevelInfo
                           format:@"Nebyla zadána cesta pro Maven, bude použita výchozí hodnota: %@", kDefaultMavenPath];
    }

    // POM files
    NSArray<NSString *> *pomFiles = input;

    [self logMessageWithLevel:AMLogLevelInfo format:@"Maven command: %@", mavenCommand];
    [self logMessageWithLevel:AMLogLevelInfo format:@"Maven path: %@", mavenPath];
    [self logMessageWithLevel:AMLogLevelInfo format:@"Files: %@", [pomFiles componentsJoinedByString:@", "]];

    return [self launchMaven:mavenPath command:mavenCommand forFiles:pomFiles];
}

-(NSArray<NSString *> *)launchMaven:(NSString *)mavenPath command:(NSString *)command forFiles:(NSArray<NSString *> *)pomFiles
{
    NSMutableArray *successfulBuilds = [[NSMutableArray alloc] init];

    for (NSString *pomFilePath in pomFiles) {
        NSTask *task = [self runTaskWithPath:mavenPath arguments:command withFile:pomFilePath];

        if ([task terminationStatus] == 0) {
            [successfulBuilds addObject:pomFilePath];
        }
        else {
            // TODO: add UI with checkbox for error output + output folder picker
            [self writeOutputFromTask:task toTargetFolder:@"~/Desktop/"];
            [self logMessageWithLevel:AMLogLevelWarn format:@"Neúspěšný build projektu: %@", pomFilePath];
        }
    }

    return successfulBuilds;
}

-(NSTask *)runTaskWithPath:(NSString *)mavenPath arguments:(NSString *)arguments withFile:(NSString *)pomFilePath
{
    NSPipe *outputPipe = [NSPipe pipe];
    NSTask *task = [[NSTask alloc] init];

    task.launchPath = mavenPath;
    task.arguments = [arguments componentsSeparatedByString:@" "];
    task.currentDirectoryPath = [pomFilePath stringByDeletingLastPathComponent];

    task.standardOutput = outputPipe;
    task.standardError = outputPipe;

    @try {
        [task launch];
    }
    @catch (NSException *exception) {
        [self logMessageWithLevel:AMLogLevelError format:@"Nepodařilo se spustit Maven. Důvod: %@", exception.reason];
    }

    [task waitUntilExit];
    return task;
}

-(void)writeOutputFromTask:(NSTask *)task toTargetFolder:(NSString *)folder
{
    NSPipe *pipe = task.standardOutput;

    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *output = [NSString stringWithUTF8String:[data bytes]];

    NSString *outputFileName = [folder stringByAppendingPathComponent:@"output.log"]; // TODO: unique name
    [output writeToFile:outputFileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@end
