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

    // Error log path
    NSString *errorLogPath = nil;
    if ([self.useErrorLogging state] == NSOnState) {
        errorLogPath = self.parameters[@"errorLogPath"];
    }

    NSArray<NSString *> *pomFiles = input;
    return [self launchMaven:mavenPath command:mavenCommand forFiles:pomFiles errorLogPath:errorLogPath];
}

-(NSArray<NSString *> *)launchMaven:(NSString *)mavenPath command:(NSString *)command forFiles:(NSArray<NSString *> *)pomFiles errorLogPath:(NSString *)errorLogPath
{
    NSMutableArray *successfulBuilds = [[NSMutableArray alloc] init];

    for (NSString *pomFilePath in pomFiles) {
        NSTask *task = [self runTaskWithPath:mavenPath arguments:command withFile:pomFilePath];

        if ([task terminationStatus] == 0) {
            [successfulBuilds addObject:pomFilePath];
        }
        else {
            [self writeOutputFromTask:task toTargetFolder:errorLogPath];
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

-(void)writeOutputFromTask:(NSTask *)task toTargetFolder:(NSString *)outputFolderPath
{
    if (outputFolderPath == nil) {
        return;
    }

    NSPipe *pipe = task.standardOutput;

    NSData *rawOutputData = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *outputData = [NSString stringWithUTF8String:[rawOutputData bytes]];

    NSString *errorLogPath = [self uniqueErrorLogForPath:outputFolderPath];

    NSError *error = nil;
    BOOL fileCreated = [outputData writeToFile:errorLogPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (fileCreated) {
        [self logMessageWithLevel:AMLogLevelInfo format:@"Vytvořen chybový soubor: %@", errorLogPath];
    }
    else {
        [self logMessageWithLevel:AMLogLevelWarn format:@"Nepodařilo se vytvořit chybový soubor: %@, důvod: %@", errorLogPath, [error description]];
    }
}

-(NSString *)uniqueErrorLogForPath:(NSString *)path
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);

    NSString *fileName = [NSString stringWithFormat:@"maven-error-%@.log", uuidString];
    NSString *errorLogPath = [path stringByAppendingPathComponent:fileName];

    CFRelease(uuid);
    CFRelease(uuidString);

    return errorLogPath;
}

@end
