//
//  MBAppDelegate.m
//  IceCube
//
//  Created by Marian Bouček on 14.12.12.
//  Copyright (c) 2012 Marian Bouček. All rights reserved.
//

#import "MBAppDelegate.h"

#import "MBMavenOutputParser.h"
#import "NSTask+MBTaskOutputParser.h"

@implementation MBAppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSURL *workingDirectory = [defaults URLForKey:kMavenWorkingDirectory];
	if (!workingDirectory) {
		NSString *dir = [NSString stringWithFormat:@"file://localhost%@", NSHomeDirectory()];
		
		workingDirectory = [[NSURL alloc] initWithString:dir];
		[defaults setURL:workingDirectory forKey:kMavenWorkingDirectory];
	}
	
	[self.pathControll setURL:workingDirectory];
	[self.pathControll setDoubleAction:@selector(showOpenDialogAction:)];
	
	[self.window setRepresentedURL:workingDirectory];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	// prozatím máme jenom jedno okno, takže po sobě hezky uklidíme
    return YES;
}

- (IBAction)runAction:(id)sender
{
	if (self.task) {
		return;
	}
	
	NSString *command = [self.commandField stringValue];
	if ([command length] == 0) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText: @"Nelze spustit prázdný příkaz."];
		
		[alert beginSheetModalForWindow:self.window
						  modalDelegate:nil
						 didEndSelector:NULL
							contextInfo:nil];
		return;
	}
	
	self.task = [[NSTask alloc] init];
	
	NSString *launchPath = [[NSUserDefaults standardUserDefaults] stringForKey:kMavenApplicationPath];
	if (!launchPath) {
		launchPath = @"/usr/bin/mvn";
		[[NSUserDefaults standardUserDefaults] setValue:launchPath forKey:kMavenApplicationPath];
	}
	[self.task setLaunchPath:launchPath];
	
	NSArray *taskArgs = [command componentsSeparatedByString:@" "];
	[self.task setArguments:taskArgs];
	
	NSURL *urlPath = [self.pathControll URL];
	NSString *path = [urlPath path];
	[self.task setCurrentDirectoryPath:path];
	
	[self taskDidStartInDirectory:path withApplication:launchPath command:command];
	
	// spuštění úlohy ve novém vlákně (normální priorita)
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
		
		MBMavenOutputParser *parser = [[MBMavenOutputParser alloc] init];
		[self.task launchWithTaskOutputBlock:^(NSString *line) {
			[parser parseLine:line];
			
			// úprava GUI musí být spuštěna na hlavním vlákně
			dispatch_async(dispatch_get_main_queue(), ^{
				NSString *lineWithNewLine = [line stringByAppendingString:@"\n"];
				[self updateOutputTextArea:lineWithNewLine];
			});
		}];
		
		[self taskDidEnd];
	});
}

-(void)updateOutputTextArea:(NSString *)line
{
	NSTextStorage *storage = [self.outputTextView textStorage];
	NSDictionary *attributes = [storage attributesAtIndex:0 effectiveRange:nil];
	
	[storage beginEditing];
	[storage appendAttributedString:[[NSAttributedString alloc] initWithString:line attributes:attributes]];
	[storage endEditing];
	
	[self.outputTextView scrollRangeToVisible:NSMakeRange([[self.outputTextView string] length], 0)];
}

- (void)taskDidStartInDirectory:(NSString *)projectDirectory
				withApplication:(NSString *)appPath
						command:(NSString *)mavenCommand
{
	[self.progressIndicator startAnimation:self];
	
	NSString *command = [NSString stringWithFormat:@"$ cd %@\n$ %@ %@\n\n", projectDirectory, appPath, mavenCommand];
	[self.outputTextView setString:command];
}

// z parseru
-(void)buildDidEnd:(NSNotification *)notification
{
	BOOL result = NO; // TODO ...
	self.buildWasSuccessful = result;
}

- (void)taskDidEnd
{
	[self.progressIndicator stopAnimation:self];
	self.task = nil;
	
	NSUserNotification *notification = [[NSUserNotification alloc] init];
	notification.soundName = NSUserNotificationDefaultSoundName;
	
	if (self.buildWasSuccessful) {
		notification.title = @"Build succeeded";
		notification.informativeText = @"Maven build úspěšně skončil.";
	}
	else {
		notification.title = @"Build error";
		notification.informativeText = @"Maven build skončil neúspěšně.";
	}
	
	[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (void)showOpenDialogAction:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setAllowsMultipleSelection:NO];
	
	[openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			NSArray *urls = [openPanel URLs];
			NSURL *url = [urls objectAtIndex:0];
			
			[self.pathControll setURL:url];
			[self.window setRepresentedURL:url];
			
			[[NSUserDefaults standardUserDefaults] setURL:url forKey:kMavenWorkingDirectory];
		}
	}];
}

- (IBAction)showPreferences:(id)sender
{
	[self.preferencesWindow makeKeyAndOrderFront:sender];
}

@end
