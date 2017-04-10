//
//  MBApplication.m
//  IceCube
//
//  Created by Marian Boucek on 27.09.14.
//  Copyright (c) 2014 Marian Bouček. All rights reserved.
//

#import "MBApplication.h"

#import "MBTaskRunnerDocument.h"
#import "MBTaskRunnerWindowController.h"
#import "MBPreferencesWindowController.h"

@implementation MBApplication

- (NSArray<NSWindowController *> *)projects
{
    NSMutableArray<NSWindowController *> *result = [[NSMutableArray alloc] init];
    NSArray *orderedDocuments = [self orderedDocuments];

    for (MBTaskRunnerDocument *document in orderedDocuments) {
        for (NSWindowController *controller in [document windowControllers]) {
            if ([controller isKindOfClass:[MBTaskRunnerWindowController class]]) {
                [result addObject:controller];
            }
        }
    }

    return result;
}

-(NSArray<MBPreferencesWindowController *> *)preferences
{
    return [NSArray arrayWithObject:[[MBPreferencesWindowController alloc] init]];
}

@end
