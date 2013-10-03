//
//  MBTaskViewController.h
//  IceCube
//
//  Created by Marian Bouček on 15.07.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "Task.h"

@interface MBTaskRunnerWindowController : NSWindowController

@property(assign) IBOutlet NSTextField *commandField;
@property(assign) IBOutlet NSTextView *outputTextView;

@property(assign) IBOutlet NSPathControl *pathControl;
@property(assign) IBOutlet NSProgressIndicator *progressIndicator;

-(IBAction)startTask:(id)sender;
-(IBAction)stopTask:(id)sender;
-(IBAction)revealFolderInFinder:(id)sender;

@property(readonly) BOOL taskRunning;
@property(readonly) Task *taskDefinition;

@end
