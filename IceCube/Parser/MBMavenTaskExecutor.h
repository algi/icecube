//
//  MBMavenTaskExecutioner.h
//  IceCube
//
//  Created by Marian Bouček on 19.07.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MBMavenOutputParserDelegate.h"

@interface MBMavenTaskExecutor : NSObject

// delegate methods will be executed on main thread using asynchronous execution
-(void)addExecutionObserver:(id<MBMavenOutputParserDelegate>)observer;
-(void)removeExecutionObserver:(id<MBMavenOutputParserDelegate>)observer;

-(void)launchMavenWithArguments:(NSString *)arguments
						 onPath:(NSURL *)path;
-(BOOL)isRunning;
-(void)terminate;

@end
