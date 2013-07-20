//
//  MBTaskViewController.h
//  IceCube
//
//  Created by Marian Bouček on 15.07.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBTaskViewController : NSObject

@property(assign) IBOutlet NSToolbarItem *runTaskButton;
@property(assign) IBOutlet NSToolbarItem *stopTaskButton;

@property(assign) IBOutlet NSTextField *commandField;
@property(assign) IBOutlet NSPathControl *pathControl;
@property(assign) IBOutlet NSTextView *outputTextView;

-(IBAction)startTask:(id)sender;
-(IBAction)stopTask:(id)sender;

@end
