//
//  MBTaskRunnerDocument.h
//  IceCube
//
//  Created by Marian Bouček on 18.08.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Task.h"

@interface MBTaskRunnerDocument : NSPersistentDocument

@property(readonly) Task *taskDefinition;

@end
