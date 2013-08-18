//
//  MBTaskRunnerDocument.m
//  IceCube
//
//  Created by Marian Bouček on 18.08.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBTaskRunnerDocument.h"

#import "MBTaskRunnerWindowController.h"

@implementation MBTaskRunnerDocument

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

- (void)makeWindowControllers
{
	id controller = [[MBTaskRunnerWindowController alloc] initWithWindowNibName:@"MBTaskRunnerDocument"];
	[self addWindowController:controller];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

@end
