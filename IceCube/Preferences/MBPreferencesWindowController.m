//
//  MBPreferencesWindowController.m
//  IceCube
//
//  Created by Marian Bouček on 22.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBPreferencesWindowController.h"

#import "MBJavaHomeService.h"

// user defaults keys
NSString * const kJavaHomeDefaultsKey = @"JavaLocation";
NSString * const kMavenHomeDefaultsKey = @"MavenLocation";

NSString * const kUseDefaultJavaLocationKey = @"UseDefaultJavaLocation";
NSString * const kUseDefaultMavenLocationKey = @"UseDefaultMavenLocation";

@implementation MBPreferencesWindowController

- (id)init
{
    return self = [super initWithWindowNibName:@"MBPreferencesWindowController"];
}

#pragma mark - User actions -
- (IBAction)selectMavenLocationDidPress:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];

    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];

    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSArray *selectedURLs = [openPanel URLs];
            [[NSUserDefaults standardUserDefaults] setURL:[selectedURLs firstObject] forKey:kMavenHomeDefaultsKey];
        }
    }];
}

- (IBAction)selectJavaLocationDidPress:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];

    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];

    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSArray *selectedURLs = [openPanel URLs];
            [[NSUserDefaults standardUserDefaults] setURL:[selectedURLs firstObject] forKey:kJavaHomeDefaultsKey];
        }
    }];
}

- (IBAction)useMavenDefaultLocationDidPress:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kMavenHomeDefaultsKey];
}

- (IBAction)useJavaDefaultLocationDidPress:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kJavaHomeDefaultsKey];
}

@end
