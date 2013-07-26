//
//  MBMavenOutputParserTestObserver.h
//  IceCube
//
//  Created by Marian Bouček on 31.03.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MBMavenOutputParser.h"

@interface MBMavenOutputParserTestObserver : NSObject<MBMavenOutputParserDelegate>

@property(readonly) NSUInteger result;
@property(readonly) NSUInteger lineCount;
@property(readonly) NSUInteger buildDidStartCount;
@property(readonly) NSUInteger buildDidEndCount;
@property(readonly) NSUInteger projectDidStartCount;

@property NSMutableArray *taskList;
@property NSMutableArray *doneTasks;

@end
