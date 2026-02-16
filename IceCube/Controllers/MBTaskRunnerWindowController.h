//
//  MBTaskViewController.h
//  IceCube
//
//  Created by Marian Bouček on 15.07.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBTaskRunnerDocument.h"

@interface MBTaskRunnerWindowController : NSWindowController <NSWindowDelegate, NSProgressReporting, NSTouchBarProvider, NSMenuItemValidation>

@property(assign) IBOutlet NSTextView *outputTextView;
@property(weak) IBOutlet NSPathControl *pathControl;
@property(weak) IBOutlet NSTextField *commandField;
@property(weak) IBOutlet NSVisualEffectView *visualEffectView;

- (IBAction)startTask:(id)sender;
- (IBAction)stopTask:(id)sender;
- (IBAction)revealFolderInFinder:(id)sender;
- (IBAction)selectWorkingDirectory:(id)sender;
- (IBAction)selectCommand:(id)sender;

@property(readonly) NSProgress *progress;
@property(readonly) BOOL taskRunning;

@property IBOutlet NSTouchBar *touchBar;
@property IBOutlet NSButton *touchRunProject;
@property IBOutlet NSButton *touchStopProject;

@end
