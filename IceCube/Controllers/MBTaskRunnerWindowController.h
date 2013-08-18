//
//  MBTaskViewController.h
//  IceCube
//
//  Created by Marian Bouček on 15.07.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBTaskRunnerWindowController : NSWindowController

@property(assign) IBOutlet NSToolbarItem *runTaskButton;
@property(assign) IBOutlet NSToolbarItem *stopTaskButton;

@property(assign) IBOutlet NSTextField *commandField;
@property(assign) IBOutlet NSTextView *outputTextView;

@property(assign) IBOutlet NSPathControl *pathControl;
@property(assign) IBOutlet NSProgressIndicator *progressIndicator;

-(IBAction)startTask:(id)sender;
-(IBAction)stopTask:(id)sender;
-(IBAction)revealFolderInFinder:(id)sender;

@property(readonly) BOOL taskRunning;

- (id)initWithOwner:(id)owner;

@end
