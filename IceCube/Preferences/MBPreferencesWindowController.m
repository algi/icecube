//
//  MBPreferencesWindowController.m
//  IceCube
//
//  Created by Marian Bouček on 22.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBPreferencesWindowController.h"

#import "MBJavaHomeService.h"

// KVO stuff
static void * MBPreferencesKVOToken = &MBPreferencesKVOToken;

static NSString * const kJavaHomePath = @"javaHome";
static NSString * const kMavenHomePath = @"mavenHome";

// defaults keys
NSString * const kJavaHomeDefaultsKey = @"java.home";
NSString * const kMavenHomeDefaultsKey = @"maven.home";

@implementation MBPreferencesWindowController

- (id)init
{
	return self = [super initWithWindowNibName:@"MBPreferencesWindowController"];
}

-(void)awakeFromNib
{
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	NSString *origJavaHOme = [prefs stringForKey:kJavaHomeDefaultsKey];
	[prefs removeObjectForKey:kJavaHomeDefaultsKey];
	
	NSString *defaultJavaHome = [prefs stringForKey:kJavaHomeDefaultsKey];
	[prefs setObject:origJavaHOme forKey:kJavaHomeDefaultsKey];
	
	NSTextField *javaDefaultLocation = self.javaDefaultLocation;
	[javaDefaultLocation setStringValue:defaultJavaHome];
	
	// register KVO for Java & Maven home
	[self addObserver:self forKeyPath:kJavaHomePath options:NSKeyValueObservingOptionNew context:MBPreferencesKVOToken];
	[self addObserver:self forKeyPath:kMavenHomePath options:NSKeyValueObservingOptionNew context:MBPreferencesKVOToken];
}

-(void)dealloc
{
	[self removeObserver:self forKeyPath:kJavaHomePath];
	[self removeObserver:self forKeyPath:kMavenHomePath];
}

#pragma mark - User selection -
- (IBAction)userDidSelectMavenChoice:(id)sender
{
	[self updateTextField:self.mavenCustomLocation fromPopUp:self.mavenPopUp withDefaultsKey:kMavenHomeDefaultsKey];
}

- (IBAction)userDidSelectJavaChoice:(id)sender
{
	[self updateTextField:self.javaCustomLocation fromPopUp:self.javaPopUp withDefaultsKey:kJavaHomeDefaultsKey];
}

- (void)updateTextField:(NSTextField *)textField fromPopUp:(NSPopUpButton *)popUpButton withDefaultsKey:(NSString *)key
{
    BOOL isCustomValueSelected = [popUpButton selectedTag] == 1;
    [textField setEditable:isCustomValueSelected];

    NSString *newValue;
    if (isCustomValueSelected) {
        newValue = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    }
    else {
        newValue = @"";
    }

    [textField setStringValue:newValue];
}

#pragma mark - Reveal in Finder -
- (IBAction)revealMavenHomeInFinder:(id)sender
{
	[self revealPathInFinderFromTextField:self.mavenCustomLocation];
}

- (IBAction)revealJavaHomeInFinder:(id)sender
{
	[self revealPathInFinderFromTextField:self.javaCustomLocation];
}

- (void)revealPathInFinderFromTextField:(NSTextField *)textField
{
	NSString *URL = [NSString stringWithFormat:@"file://%@", [textField stringValue]];
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[[NSURL URLWithString:URL]]];
}

#pragma mark - KVO observation -
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context != MBPreferencesKVOToken) {
		return;
	}
	
	NSString *defaultsKey = nil;
	if ([keyPath isEqualTo:kJavaHomePath]) {
		defaultsKey = kJavaHomeDefaultsKey;
	}
	else if ([keyPath isEqualTo:kMavenHomePath]) {
		defaultsKey = kMavenHomeDefaultsKey;
	}
	else {
		NSLog(@"Unrecognized keypath in KVO observation: %@", keyPath);
		return;
	}
	
	NSString *newValue = change[NSKeyValueChangeNewKey];
	if (newValue == nil || [newValue isEqualToString:@""]) {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:defaultsKey];
	}
	else {
		[[NSUserDefaults standardUserDefaults] setObject:newValue forKey:defaultsKey];
	}
}

@end
