//
//  MBMavenServiceCallback.h
//  IceCube
//
//  Created by Marian Bouček on 19.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

@protocol MBMavenServiceCallback <NSObject>

- (void)mavenTaskDidWriteLine:(NSString *)line;

- (void)mavenTaskDidFinishSuccessfully:(BOOL)result error:(NSError *)error;

@end
