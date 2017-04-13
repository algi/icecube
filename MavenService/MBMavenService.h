//
//  MBMavenService.h
//  IceCube
//
//  Created by Marian Bouček on 19.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

@protocol MBMavenService <NSObject>

#pragma mark - Maven build
- (void)buildProjectWithMaven:(NSString *)launchPath
                    arguments:(NSString *)arguments
                  environment:(NSDictionary *)environment
             currentDirectory:(NSURL *)currentDirectory;

- (void)terminateBuild;

@end
