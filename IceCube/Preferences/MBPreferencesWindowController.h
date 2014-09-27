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

@property (weak) IBOutlet NSButton *mavenDefaultLocation;
@property (weak) IBOutlet NSTextField *mavenLocation;

@property (weak) IBOutlet NSButton *javaDefaultLocation;
@property (weak) IBOutlet NSTextField *javaLocation;

- (IBAction)selectMavenLocationDidPress:(id)sender;
- (IBAction)selectJavaLocationDidPress:(id)sender;

- (IBAction)useMavenDefaultLocationDidPress:(id)sender;
- (IBAction)useJavaDefaultLocationDidPress:(id)sender;

// initializes window with correct NIB name (no other init method should be used)
- (id)init;

@end
