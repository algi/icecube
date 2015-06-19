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

@implementation MBApplication

- (NSArray *)projects
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSArray *orderedDocuments = [[NSApplication sharedApplication] orderedDocuments];

    for (MBTaskRunnerDocument *document in orderedDocuments) {
        for (NSWindowController *controller in [document windowControllers]) {
            if ([controller isKindOfClass:[MBTaskRunnerWindowController class]]) {
                [result addObject:controller];
            }
        }
    }

    return result;
}

@end
