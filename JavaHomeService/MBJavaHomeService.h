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
 * @param reply reply block (if result is nil, then error contains informations about error)
 */
- (void)findDefaultJavaLocationForVersionwithReply:(void(^)(NSString *result, NSError *error))reply;

@end
