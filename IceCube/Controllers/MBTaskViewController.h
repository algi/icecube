//
//  MBTaskViewController.h
//  IceCube
//
//  Created by Marian Bouček on 15.07.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBTaskViewController : NSObject

@property(assign) NSTextField *commands;
@property(assign) NSTextField *arguments;
@property(assign) NSTextView *outputArea;

-(void)startTask;
-(void)stopTask;

@end
