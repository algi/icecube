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
    if ([input isKindOfClass:[NSString class]]) {
        [self logMessageWithLevel:AMLogLevelInfo format:@"Vstupní text: %@", [input string]];
    }
    else if ([input isKindOfClass:[NSArray class]]) {
        [self logMessageWithLevel:AMLogLevelInfo format:@"První položka: %@", [input firstObject]];
    }
    else {
        [self logMessageWithLevel:AMLogLevelWarn format:@"Nerozpoznaný typ vstupu: %@, hodnota: %@", [input class], input];
    }

    [self logMessageWithLevel:AMLogLevelInfo format:@"Text field: %@", [self.textField stringValue]];

    return input;
}

@end
