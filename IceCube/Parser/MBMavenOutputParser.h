//
//  MBMavenOutputParser.h
//  IceCube
//
//  Created by Marian Bouček on 31.03.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MBMavenOutputParserDelegate.h"

extern NSString * const kMavenNotifiactionBuildDidStart;
extern NSString * const kMavenNotifiactionBuildDidEnd;
extern NSString * const kMavenNotifiactionProjectDidStart;

extern NSString * const kMavenNotifiactionBuildDidStart_taskList;
extern NSString * const kMavenNotifiactionBuildDidEnd_result;
extern NSString * const kMavenNotifiactionProjectDidStart_taskName;

@interface MBMavenOutputParser : NSObject

-(instancetype)initWithDelegate:(id<MBMavenOutputParserDelegate>)delegate;

-(void)parseLine:(NSString *)line;

@end
