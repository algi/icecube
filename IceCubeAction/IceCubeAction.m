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
        [self logMessageWithLevel:AMLogLevelInfo format:@"Nebyl zadán příkaz pro Maven, bude použit výchozí příkaz \"clean install\"..."];

        mavenCommand = @"clean install";
    }

    return input;
}

@end
