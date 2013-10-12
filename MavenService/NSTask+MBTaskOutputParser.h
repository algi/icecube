//
//  NSTask+MBTaskOutputParser.h
//  IceCube
//
//  Created by Marian Bouček on 17.07.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

@interface NSTask (MBTaskOutputParser)

- (BOOL)launchTaskWithTaskOutputBlock:(void (^)(NSString *))delegateBlock error:(__autoreleasing NSError **)error;

@end
