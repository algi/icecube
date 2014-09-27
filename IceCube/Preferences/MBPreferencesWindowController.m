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

@implementation MBPreferencesWindowController

- (id)init
{
    return self = [super initWithWindowNibName:@"MBPreferencesWindowController"];
}

#pragma mark - User actions -
- (IBAction)selectMavenLocationDidPress:(id)sender
{
    NSLog(@"Not yet supported!");
}

- (IBAction)selectJavaLocationDidPress:(id)sender
{
    NSLog(@"Not yet supported!");
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
