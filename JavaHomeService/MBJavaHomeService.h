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

/**
 * Find all available Java Virtual Machines (JVMs).
 *
 * @param reply Reply with exact output as it gives /usr/libexec/java_home -V command.
 */
- (void)findAvaliableJavaVirtualMachinesWithReply:(void(^)(NSArray *machines))reply;

@end
