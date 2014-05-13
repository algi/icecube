//
//  MBPreferencesWindowController.h
//  IceCube
//
//  Created by Marian Bouček on 22.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBUserPreferences.h"

@interface MBPreferencesWindowController : NSWindowController

@property (weak) IBOutlet NSPopUpButton *mavenPopUp;
@property (weak) IBOutlet NSTextField *mavenDefaultLocation;
@property (weak) IBOutlet NSTextField *mavenCustomLocation;

@property (weak) IBOutlet NSPopUpButton *javaPopUp;
@property (weak) IBOutlet NSTextField *javaDefaultLocation;
@property (weak) IBOutlet NSTextField *javaCustomLocation;

// used in UI for binding values of user preferences
@property MBUserPreferences *userPreferences;

// initializes window with correct NIB name (no other init method should be used)
- (id)init;

- (IBAction)userDidSelectMavenChoice:(id)sender;
- (IBAction)userDidSelectJavaChoice:(id)sender;
- (IBAction)revealMavenHomeInFinder:(id)sender;
- (IBAction)revealJavaHomeInFinder:(id)sender;

@end
