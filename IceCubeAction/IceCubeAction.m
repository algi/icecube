//
//  IceCubeAction.m
//  IceCubeAction
//
//  Created by Marian Bouček on 03.04.17.
//  Copyright © 2017 Marian Bouček. All rights reserved.
//

#import "IceCubeAction.h"

// define our own version of localized string lookup
// we need to look in our own bundle, not main application bundle
#define MBLocalizedString(key, comment) \
    [[self bundle] localizedStringForKey:(key) value:@"" table:nil]

@implementation IceCubeAction

static NSString * const kDefaultMavenCommand = @"clean install";
static NSString * const kDefaultMavenPath = @"/usr/share/maven/bin/mvn";

-(id)runWithInput:(id)input error:(NSError * _Nullable __autoreleasing *)error
{
    // Maven command
    NSString *mavenCommand = self.parameters[@"mavenCommand"];
    if (mavenCommand == nil) {
        mavenCommand = kDefaultMavenCommand;

        NSString *message = MBLocalizedString(@"No Maven command specified, will use default: %@",
                                              @"Default {Maven command} will be used instead of empty command.");
        [self logMessageWithLevel:AMLogLevelInfo format:message, kDefaultMavenCommand];
    }

    // Maven path
    NSString *mavenPath = self.parameters[@"mavenPath"];
    if (mavenPath == nil) {
        mavenPath = kDefaultMavenPath;

        NSString *message = MBLocalizedString(@"No Maven installation directory specified, will use default: %@",
                                              @"Default {Maven installation directory} will be used instead of empty path.");
        [self logMessageWithLevel:AMLogLevelInfo format:message, kDefaultMavenPath];
    }

    // Error log path
    NSString *errorLogPath = nil;
    if ([self.useErrorLogging state] == NSControlStateValueOn) {
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
        if (task == nil) {
            continue;
        }

        // check status only if we were able to invoke Maven
        if ([task terminationStatus] == 0) {
            [successfulBuilds addObject:pomFilePath];
        }
        else {
            [self writeOutputFromTask:task toTargetFolder:errorLogPath];

            NSString *message = MBLocalizedString(@"Build failure for project: %@",
                                                  @"Unable to build Maven project for {path}.");
            [self logMessageWithLevel:AMLogLevelWarn format:message, pomFilePath];
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
        [task waitUntilExit];
        return task;
    }
    @catch (NSException *exception) {
        NSString *message = MBLocalizedString(@"Unable to launch Maven. Reason: %@",
                                              @"Unable to launch Maven due to {error}.");
        [self logMessageWithLevel:AMLogLevelError format:message, exception.reason];
        return nil;
    }
}

-(void)writeOutputFromTask:(NSTask *)task toTargetFolder:(NSString *)outputFolderPath
{
    if (task == nil || outputFolderPath == nil) {
        return;
    }

    NSPipe *pipe = task.standardOutput;

    NSData *rawOutputData = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *outputData = [NSString stringWithUTF8String:[rawOutputData bytes]];

    NSString *errorLogPath = [self uniqueErrorLogForPath:outputFolderPath];

    NSError *error = nil;
    BOOL fileCreated = [outputData writeToFile:errorLogPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (fileCreated) {
        NSString *message = MBLocalizedString(@"Error file created at path: %@",
                                              @"Error file was created at {path}.");
        [self logMessageWithLevel:AMLogLevelInfo format:message, errorLogPath];
    }
    else {
        NSString *message = MBLocalizedString(@"Unable to create error log at path: %@, reason: %@",
                                              @"Unable to create error log at {path} for {reason}.");
        [self logMessageWithLevel:AMLogLevelWarn format:message, errorLogPath, [error description]];
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
