//
//  MBTaskViewController.m
//  IceCube
//
//  Created by Marian Bouček on 15.07.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBTaskRunnerWindowController.h"

#import "MBTaskRunnerDocument.h"

#import "MBMavenService.h"
#import "MBMavenServiceCallback.h"

#import "MBMavenOutputParser.h"
#import "MBMavenParserDelegate.h"

#import "MBUserPreferences.h"

@interface MBTaskRunnerWindowController () <MBMavenServiceCallback, MBMavenParserDelegate>

@property NSXPCConnection *connection;

@property BOOL taskRunning;
@property Task *taskDefinition;

@property MBMavenOutputParser *parser;

@end

@implementation MBTaskRunnerWindowController

- (id)init
{
	return self = [super initWithWindowNibName:@"MBTaskRunnerDocument"];
}

- (void)windowDidLoad
{
	self.taskDefinition = [[self document] taskDefinition];
	
	NSURL *directoryURL = [NSURL URLWithString:self.taskDefinition.directory];
	
	[self.pathControl setURL:directoryURL];
	[self.pathControl setDoubleAction:@selector(showOpenDialogAction:)];
}

- (void)showOpenDialogAction:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setAllowsMultipleSelection:NO];
	
	[openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			NSURL *url = [openPanel URLs][0];
			[self.pathControl setURL:url];
			
			MBTaskRunnerDocument *document = [self document];
			document.taskDefinition.directory = [url absoluteString];
		}
	}];
}

#pragma mark IB actions -
-(IBAction)startTask:(id)sender
{
	if (self.taskRunning) {
		return;
	}
	
	self.parser = [[MBMavenOutputParser alloc] initWithDelegate:self];
	
	// create Maven execution environment
	NSString *args = self.taskDefinition.command;
	if ([args length] == 0) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText: @"Nelze spustit prázdný příkaz."];
		
		[alert beginSheetModalForWindow:[self window]
						  modalDelegate:nil
						 didEndSelector:NULL
							contextInfo:nil];
		return;
	}
	NSURL *path = [NSURL URLWithString:self.taskDefinition.directory];
	
	NSString *mavenPath = [[MBUserPreferences standardUserPreferences] mavenHome];
	NSDictionary *environment = @{@"JAVA_HOME": [[MBUserPreferences standardUserPreferences] javaHome]};
	
	// prepare UI
	self.taskRunning = YES;
	[self.progressIndicator setIndeterminate:YES];
	[self.progressIndicator startAnimation:self];
	
	NSString *executionHeader = [NSString stringWithFormat:@"$ cd %@\n$ %@ %@\n\n",
								 path,
								 mavenPath,
								 args];
	[self.outputTextView setString:executionHeader];
	
	// launch task
	[self launchMaven:mavenPath withArguments:args environment:environment atPath:path withReply:^(BOOL launchSuccessful, NSError *error) {
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self stopProgressBarWithStepForward:YES];
			[self invalidateConnection];
			
			if (! launchSuccessful) {
				[[NSAlert alertWithError:error] beginSheetModalForWindow:self.window
													   completionHandler:^(NSModalResponse returnCode) {}];
			}
		});
	}];
}

-(IBAction)stopTask:(id)sender
{
	[[self.connection remoteObjectProxy] terminateTask];
	[self invalidateConnection];
}

-(IBAction)revealFolderInFinder:(id)sender
{
	NSArray *fileURLs = @[self.pathControl.URL];
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:fileURLs];
}

#pragma mark - MBMavenServiceCallback -
- (void)mavenTaskDidWriteLine:(NSString *)line
{
	[self.parser parseLine:line];
}

#pragma mark - MBMavenParserDelegate -
-(void)buildDidStartWithTaskList:(NSArray *)taskList
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.progressIndicator setMinValue:0];
		[self.progressIndicator setMaxValue:[taskList count] + 1];
		[self.progressIndicator setDoubleValue:0];
		
		[self.progressIndicator setIndeterminate:NO];
	});
}

-(void)projectDidStartWithName:(NSString *)name
{
	dispatch_async(dispatch_get_main_queue(), ^{
		double doubleValue = [self.progressIndicator doubleValue] + 1;
		[self.progressIndicator setDoubleValue:doubleValue];
	});
}

-(void)buildDidEndSuccessfully:(BOOL)buildWasSuccessful
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self stopProgressBarWithStepForward:YES];
		
		NSUserNotification *notification = [[NSUserNotification alloc] init];
		notification.soundName = NSUserNotificationDefaultSoundName;
		
		if (buildWasSuccessful) {
			notification.title = NSLocalizedString(@"Build succeeded", @"Maven build did suceeded.");
			notification.informativeText = NSLocalizedString(@"Maven build did end successfuly.", @"Maven build did end successfuly.");
		}
		else {
			notification.title = NSLocalizedString(@"Build error", @"Maven build didn't succeed.");
			notification.informativeText = NSLocalizedString(@"Maven build didn't end successfuly.", @"Maven build didn't end successfuly.");
		}
		
		[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
	});
}

-(void)newLineDidRecieve:(NSString *)line
{
	dispatch_async(dispatch_get_main_queue(), ^{
		NSTextStorage *storage = [self.outputTextView textStorage];
		NSDictionary *attributes = [storage attributesAtIndex:0 effectiveRange:nil];
		
		[storage beginEditing];
		[storage appendAttributedString:[[NSAttributedString alloc] initWithString:[line stringByAppendingString:@"\n"]
																		attributes:attributes]];
		[storage endEditing];
		
		[self.outputTextView scrollRangeToVisible:NSMakeRange([[self.outputTextView string] length], 0)];
	});
}

#pragma mark - Other methods -
- (void)stopProgressBarWithStepForward:(BOOL)oneStepFurther
{
	if (oneStepFurther) {
		double doubleValue = [self.progressIndicator doubleValue] + 1;
		[self.progressIndicator setDoubleValue:doubleValue];
	}
	
	[self.progressIndicator stopAnimation:nil];
	self.taskRunning = NO;
}

#pragma mark - XPC connection -
- (void)launchMaven:(NSString *)launchPath
	  withArguments:(NSString *)arguments
		environment:(NSDictionary *)environment
			 atPath:(NSURL *)path
		  withReply:(void (^)(BOOL launchSuccessful, NSError *error))reply
{
	self.connection = [[NSXPCConnection alloc] initWithServiceName:@"cz.boucekm.MavenService"];
	self.connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MBMavenService)];
	
	self.connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MBMavenServiceCallback)];
	self.connection.exportedObject = self;
	
	[self.connection resume];
	[[self.connection remoteObjectProxy] launchMaven:launchPath
									   withArguments:arguments
										 environment:environment
											  atPath:path
										   withReply:reply];
}

- (void)invalidateConnection
{
	self.connection.exportedObject = nil;
	[self.connection invalidate];
}

@end
