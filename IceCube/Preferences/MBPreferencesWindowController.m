//
//  MBPreferencesWindowController.m
//  IceCube
//
//  Created by Marian Bouček on 22.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBPreferencesWindowController.h"

#import "MBJavaHomeService.h"

static NSString * const kMavenApplicationPath = @"maven.application.path";
static NSString * const kJavaHomePath = @"java.home.path";

@implementation MBPreferencesWindowController

- (id)init
{
    return self = [super initWithWindowNibName:@"MBPreferencesWindowController"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	
	// pokud v této fázi budou nastaveny komponenty dle bindingu, tak by se daly nastavit přidružené komponenty
}

- (IBAction)userDidSelectMavenChoice:(id)sender
{
	NSPopUpButton *mavenPopUp = self.mavenPopUp;
	NSInteger selectedTag = [mavenPopUp selectedTag];
	switch (selectedTag) {
		case 0: // default
		{
			break;
		}
		case 1: // custom
		{
			break;
		}
		default: // error in app ^^
			@throw [[NSException alloc] initWithName:@"MBIllegalUIStateException"
											  reason:@"Unknown selected tag in Maven pop up."
											userInfo:nil];
			break;
	}
}

- (IBAction)userDidSelectJavaChoice:(id)sender
{
	NSPopUpButton *javaPopUp = self.javaPopUp;
	NSInteger selectedTag = [javaPopUp selectedTag];
	switch (selectedTag) {
		case 1: // default
		{
			break;
		}
		case 2: // custom
		{
			break;
		}
		default: // number means version of Java (eg. 6 = Java 6)
		{
			break;
		}
	}
}

- (IBAction)revealMavenHomeInFinder:(id)sender
{
	[self revealPathInFinder:[[NSUserDefaults standardUserDefaults] objectForKey:kMavenApplicationPath]];
}

- (IBAction)revealJavaHomeInFinder:(id)sender
{
	[self revealPathInFinder:[[NSUserDefaults standardUserDefaults] objectForKey:kJavaHomePath]];
}

- (void)revealPathInFinder:(NSString *)path
{
	NSString *URL = [NSString stringWithFormat:@"file://%@", path];
	NSArray *fileURLs = @[[NSURL URLWithString:URL]];
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:fileURLs];
}

@end
