//
//  MBMavenTaskExecutioner.h
//  IceCube
//
//  Created by Marian Bouček on 19.07.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MBMavenServiceCallback;

@interface MBMavenTaskExecutor : NSObject

@property(weak) id<MBMavenServiceCallback> executionObserver;

-(void)launchMavenWithArguments:(NSString *)arguments
						 onPath:(NSURL *)path;
-(BOOL)isRunning;
-(void)terminate;

@end
