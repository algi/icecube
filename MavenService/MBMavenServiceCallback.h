//
//  MBMavenServiceCallback.h
//  IceCube
//
//  Created by Marian Bouček on 19.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MBMavenServiceCallback <NSObject>

- (void)taskDidWriteLine:(NSString *)line;

@end