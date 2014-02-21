//
//  MBTaskRunnerDocument.h
//  IceCube
//
//  Created by Marian Bouček on 18.08.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

@interface MBTaskRunnerDocument : NSDocument

@property (nonatomic, strong) NSURL * workingDirectory;
@property (nonatomic, copy) NSString * command;

@end
