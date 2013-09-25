//
//  MBMavenService.h
//  IceCube
//
//  Created by Marian Bouček on 19.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MBMavenService <NSObject>

- (void)launchMavenWithArguments:(NSString *)arguments
						  onPath:(NSURL *)path
					   withReply:(void (^)(BOOL launchSuccessful, NSError *error))reply;

- (void)terminateTask;

@end
