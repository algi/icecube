//
//  MBTaskViewController.h
//  IceCube
//
//  Created by Marian Bouček on 15.07.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBTaskRunnerDocument.h"

@interface MBTaskRunnerWindowController : NSWindowController <NSWindowDelegate>

@property(weak) IBOutlet NSTextField *commandField;
@property(assign) IBOutlet NSTextView *outputTextView;

@property(weak) IBOutlet NSPathControl *pathControl;
@property(weak) IBOutlet NSProgressIndicator *progressIndicator;

- (IBAction)startTask:(id)sender;
- (IBAction)stopTask:(id)sender;
- (IBAction)revealFolderInFinder:(id)sender;

@property(readonly) BOOL taskRunning;

@end
