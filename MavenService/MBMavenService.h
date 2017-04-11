//
//  MBMavenService.h
//  IceCube
//
//  Created by Marian Bouček on 19.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

@protocol MBMavenService <NSObject>

- (void)launchMaven:(NSString *)launchPath
      withArguments:(NSString *)arguments
        environment:(NSDictionary *)environment
             atPath:(NSURL *)path;

- (void)terminateTask;

@end
