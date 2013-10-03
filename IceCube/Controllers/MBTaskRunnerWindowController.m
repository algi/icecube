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
	
	self.connection = [[NSXPCConnection alloc] initWithServiceName:@"cz.boucekm.MavenService"];
	self.connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MBMavenService)];
	
	self.connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MBMavenServiceCallback)];
	self.connection.exportedObject = self;
	
	__weak MBTaskRunnerWindowController *weakSelf = self;
	self.connection.interruptionHandler = ^{
		MBTaskRunnerWindowController *strongSelf = weakSelf;
		strongSelf.taskRunning = NO;
	};
	self.connection.invalidationHandler = ^{
		MBTaskRunnerWindowController *strongSelf = weakSelf;
		strongSelf.taskRunning = NO;
	};
	
	[self.connection resume];
	
	id replyBlock = ^(BOOL launchSuccessful, NSError *error) {
		if (! launchSuccessful) {
			NSLog(@"Error while creating Maven task:\n%@", [error localizedDescription]);
		}
	};
	
	NSString *mavenPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"maven.application.path"];
	NSDictionary *environment = @{@"JAVA_HOME": [[NSUserDefaults standardUserDefaults] objectForKey:@"java.home.path"]};
	
	[[self.connection remoteObjectProxy] launchMaven:mavenPath
									   withArguments:args
										 environment:environment
											  atPath:path
										   withReply:replyBlock];
}

-(IBAction)stopTask:(id)sender
{
	[[self.connection remoteObjectProxy] terminateTask];
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
-(void)task:(NSString *)executable willStartWithArguments:(NSString *)arguments onPath:(NSString *)projectDirectory
{
	dispatch_async(dispatch_get_main_queue(), ^{
		self.taskRunning = YES;
		[self.progressIndicator startAnimation:self];
		
		NSString *executionHeader = [NSString stringWithFormat:@"$ cd %@\n$ %@ %@\n\n",
									 projectDirectory,
									 executable,
									 arguments];
		[self.outputTextView setString:executionHeader];
	});
}

-(void)buildDidStartWithTaskList:(NSArray *)taskList
{
	// we are not interested for now
}

-(void)projectDidStartWithName:(NSString *)name
{
	// we are not interested for now
}

-(void)buildDidEndSuccessfully:(BOOL)buildWasSuccessful
{
	dispatch_async(dispatch_get_main_queue(), ^{
		self.taskRunning = NO;
		[self.progressIndicator stopAnimation:self];
		
		NSUserNotification *notification = [[NSUserNotification alloc] init];
		notification.soundName = NSUserNotificationDefaultSoundName;
		
		if (buildWasSuccessful) {
			notification.title = @"Build succeeded";
			notification.informativeText = @"Maven build úspěšně skončil.";
		}
		else {
			notification.title = @"Build error";
			notification.informativeText = @"Maven build skončil neúspěšně.";
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

@end
