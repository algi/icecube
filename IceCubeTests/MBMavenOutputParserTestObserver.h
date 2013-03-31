//
//  MBMavenOutputParserTestObserver.h
//  IceCube
//
//  Created by Marian Bouček on 31.03.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MBMavenOutputParser.h"

@interface MBMavenOutputParserTestObserver : NSObject

@property BOOL result;
@property(assign) NSMutableArray *taskList;
@property(assign) NSMutableArray *doneTasks;

@end
