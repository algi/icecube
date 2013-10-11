//
//  MBJavaHomeService.h
//  IceCube
//
//  Created by Marian Bouček on 22.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

@protocol MBJavaHomeService <NSObject>

/**
 * Finds Java location for specified version.
 *
 * @param reply reply block when location was found
 */
- (void)findDefaultJavaLocationForVersionwithReply:(void(^)(NSString *result))reply;

/**
 * Find all available Java Virtual Machines (JVMs).
 *
 * @param reply Reply with exact output as it gives /usr/libexec/java_home -V command.
 */
- (void)findAvaliableJavaVirtualMachinesWithReply:(void(^)(NSArray *machines))reply;

@end
