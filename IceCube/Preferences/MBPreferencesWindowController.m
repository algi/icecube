//
//  MBPreferencesWindowController.m
//  IceCube
//
//  Created by Marian Bouček on 22.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBPreferencesWindowController.h"

#import "MBJavaHomeService.h"

@implementation MBPreferencesWindowController

- (id)init
{
    self = [super initWithWindowNibName:@"MBPreferencesWindowController"];
	if (self) {
		_userPreferences = [MBUserPreferences standardUserPreferences];
	}
	return self;
}

#pragma mark - User selection -
- (IBAction)userDidSelectMavenChoice:(id)sender
{
	[self updateTextField:self.mavenCustomLocation fromPopUp:self.mavenPopUp withResetBlock:^{
		[self.userPreferences setCustomMavenHome:nil];
	}];
}

- (IBAction)userDidSelectJavaChoice:(id)sender
{
	[self updateTextField:self.javaCustomLocation fromPopUp:self.javaPopUp withResetBlock:^{
		[self.userPreferences setCustomJavaHome:nil];
	}];
}

- (void)updateTextField:(NSTextField *)textField fromPopUp:(NSPopUpButton *)popUpButton withResetBlock:(void(^)())resetBlock
{
	BOOL isCustomValueSelected = [popUpButton selectedTag] == 1;
	[textField setEditable:isCustomValueSelected];
	
	if (! isCustomValueSelected) {
		resetBlock();
	}
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

@end
