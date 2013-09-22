//
//  MBJavaHomeService.h
//  IceCube
//
//  Created by Marian Bouček on 22.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MBJavaHomeService <NSObject>

/**
 * Finds Java location for specified version.
 *
 * @param version required Java version (eg. 1.6, 1.7, etc.)
 * @param reply reply block when location was found
 */
- (void)findJavaLocationForVersion:(NSString *)version
						 withReply:(void(^)(NSString *result))reply;

@end
