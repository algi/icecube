//
//  IceCubeAction.m
//  IceCubeAction
//
//  Created by Marian Bouček on 03.04.17.
//  Copyright © 2017 Marian Bouček. All rights reserved.
//

#import "IceCubeAction.h"

@implementation IceCubeAction

-(id)runWithInput:(id)input error:(NSError * _Nullable __autoreleasing *)error
{
    NSString *mavenCommand = self.parameters[@"mavenCommand"];

    if (mavenCommand == nil) {
        NSString *defaultMavenCommand = @"clean install";

        [self logMessageWithLevel:AMLogLevelInfo format:@"Nebyl zadán příkaz pro Maven, bude použit výchozí příkaz \"%@\"...", defaultMavenCommand];

        mavenCommand = defaultMavenCommand;
    }

    NSString *mavenPath = self.parameters[@"mavenPath"];

    if (mavenPath == nil) {
        NSString *defaultMavenPath = @"/usr/share/maven/bin/mvn";

        [self logMessageWithLevel:AMLogLevelInfo format:@"Nebyla zadána cesta pro Maven, bude použita výchozí hodnota: %@", defaultMavenPath];

        mavenPath = defaultMavenPath;
    }

    [self logMessageWithLevel:AMLogLevelInfo format:@"Maven command: %@", mavenCommand];
    [self logMessageWithLevel:AMLogLevelInfo format:@"Maven path: %@", mavenPath];

    return input;
}

@end
