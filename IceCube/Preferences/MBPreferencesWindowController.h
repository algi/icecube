//
//  MBPreferencesWindowController.h
//  IceCube
//
//  Created by Marian Bouček on 22.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

extern NSString * const kJavaHomeDefaultsKey;
extern NSString * const kMavenHomeDefaultsKey;

extern NSString * const kUseDefaultJavaLocationKey;
extern NSString * const kUseDefaultMavenLocationKey;

@interface MBPreferencesWindowController : NSWindowController

@property (weak) IBOutlet NSButton *mavenDefaultLocation;
@property (weak) IBOutlet NSTextField *mavenLocation;
@property (weak) IBOutlet NSTextField *mavenVersion;

@property (weak) IBOutlet NSButton *javaDefaultLocation;
@property (weak) IBOutlet NSTextField *javaLocation;
@property (weak) IBOutlet NSTextField *javaVersion;

@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

- (IBAction)selectMavenLocationDidPress:(id)sender;
- (IBAction)selectJavaLocationDidPress:(id)sender;

- (IBAction)useMavenDefaultLocationDidPress:(id)sender;
- (IBAction)useJavaDefaultLocationDidPress:(id)sender;

// initializes window with correct NIB name (no other init method should be used)
- (id)init;

@end
