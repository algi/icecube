//
//  MBMavenService.h
//  IceCube
//
//  Created by Marian Bouček on 19.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

@protocol MBMavenService <NSObject>

#pragma mark - Maven build
- (void)buildProjectWithMaven:(NSString *)launchPath
                    arguments:(NSString *)arguments
                  environment:(NSDictionary *)environment
             currentDirectory:(NSURL *)currentDirectory;

- (void)terminateBuild;

// TODO: move to a separate service
// this method doesn't use MBMavenServiceCallback, please provide callback as parameter
// NSTask invocation won't react to -terminateBuildTask (because it's blocking execution with callback)
/*
- (void)readVersionInformationWithMaven:(NSString *)launchPath
                            environment:(NSDictionary *)environment
                               callback:(void(^)(NSString *, NSString *))callback; // Maven version, Java version
*/

#pragma mark - Unit testing
- (void)parseMavenOutput:(NSString *)mavenOutput;

@end
