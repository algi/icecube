//
//  MBPreferencesWindowController.h
//  IceCube
//
//  Created by Marian Bouček on 22.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

extern NSString * const kJavaHomeDefaultsKey;
extern NSString * const kMavenHomeDefaultsKey;

@interface MBPreferencesWindowController : NSWindowController

@property (weak) IBOutlet NSPopUpButton *mavenPopUp;
@property (weak) IBOutlet NSTextField *mavenDefaultLocation;
@property (weak) IBOutlet NSTextField *mavenCustomLocation;

@property (weak) IBOutlet NSPopUpButton *javaPopUp;
@property (weak) IBOutlet NSTextField *javaDefaultLocation;
@property (weak) IBOutlet NSTextField *javaCustomLocation;

@property (copy) NSString *javaHome;
@property (copy) NSString *mavenHome;

// initializes window with correct NIB name (no other init method should be used)
- (id)init;

- (IBAction)userDidSelectMavenChoice:(id)sender;
- (IBAction)userDidSelectJavaChoice:(id)sender;
- (IBAction)revealMavenHomeInFinder:(id)sender;
- (IBAction)revealJavaHomeInFinder:(id)sender;

@end
