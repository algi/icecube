//
//  NSTask+MBTaskOutputParser.h
//  IceCube
//
//  Created by Marian Bouček on 17.07.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSTask (MBTaskOutputParser)

- (BOOL)launchWithTaskOutputBlock:(void (^)(NSString *))delegateBlock error:(__autoreleasing NSError *)error;

@end
