//
//  MBAppDelegate.h
//  IceCube
//
//  Created by Marian Bouček on 14.12.12.
//  Copyright (c) 2012 Marian Bouček. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MBAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *preferencesWindow;

#pragma mark - Actions -
- (IBAction)showPreferences:(id)sender;

@end