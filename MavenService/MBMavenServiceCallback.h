//
//  MBMavenServiceCallback.h
//  IceCube
//
//  Created by Marian Bouček on 19.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

@protocol MBMavenServiceCallback <NSObject>

- (void)mavenTaskDidStartWithTaskList:(NSArray *)taskList;
- (void)mavenTaskDidStartProject:(NSString *)name;

- (void)mavenTaskDidWriteLine:(NSString *)line;

- (void)mavenTaskDidFinishSuccessfullyWithResult:(BOOL)result;
- (void)mavenTaskDidFinishWithError:(NSError *)error;

@end
