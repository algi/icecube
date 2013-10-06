//
//  MBPreferencesWindowController.h
//  IceCube
//
//  Created by Marian Bouček on 22.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

@interface MBPreferencesWindowController : NSWindowController

@property (weak) IBOutlet NSPopUpButton *mavenPopUp;
@property (weak) IBOutlet NSTextField *mavenDefaultLocation;
@property (weak) IBOutlet NSTextField *mavenCustomLocation;

@property (weak) IBOutlet NSPopUpButton *javaPopUp;
@property (weak) IBOutlet NSTextField *javaDefaultLocation;
@property (weak) IBOutlet NSTextField *javaCustomLocation;

- (IBAction)userDidSelectMavenChoice:(id)sender;
- (IBAction)userDidSelectJavaChoice:(id)sender;
- (IBAction)revealMavenHomeInFinder:(id)sender;
- (IBAction)revealJavaHomeInFinder:(id)sender;

// initializes window with correct NIB name
- (id)init;

@end
