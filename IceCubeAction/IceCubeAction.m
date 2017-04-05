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

    [self logMessageWithLevel:AMLogLevelInfo format:@"Maven command: %@", mavenCommand];
    [self logMessageWithLevel:AMLogLevelInfo format:@"Maven path: %@", mavenPath];

    return input;
}

@end
