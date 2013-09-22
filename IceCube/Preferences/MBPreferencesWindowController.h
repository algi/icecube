//
//  MBPreferencesWindowController.h
//  IceCube
//
//  Created by Marian Bouček on 22.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MBPreferencesWindowController : NSWindowController

@property (weak) IBOutlet NSPopUpButton *mavenPopUp;
@property (weak) IBOutlet NSTextField *mavenDefaultLocation;
@property (weak) IBOutlet NSTextField *mavenCustomLocation;

@property (weak) IBOutlet NSPopUpButton *javaPopUp;
@property (weak) IBOutlet NSTextField *javaDefaultLocation;
@property (weak) IBOutlet NSTextField *javaCustomLocation;

// initializes window with correct NIB name
- (id)init;

@end
