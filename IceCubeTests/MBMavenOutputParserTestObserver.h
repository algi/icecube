//
//  MBMavenOutputParserTestObserver.h
//  IceCube
//
//  Created by Marian Bouček on 31.03.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

@import Foundation;

#import "MBMavenServiceCallback.h"

@interface MBMavenOutputParserTestObserver : NSObject<MBMavenServiceCallback>

@property(readonly) NSUInteger result;
@property(readonly) NSUInteger lineCount;
@property(readonly) NSUInteger buildDidStartCount;
@property(readonly) NSUInteger buildDidEndCount;
@property(readonly) NSUInteger projectDidStartCount;

@property NSMutableArray *taskList;
@property NSMutableArray *doneTasks;

@end
