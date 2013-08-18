//
//  MBTaskViewController.m
//  IceCube
//
//  Created by Marian Bouček on 15.07.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBTaskRunnerWindowController.h"

#import "MBMavenTaskExecutor.h"
#import "MBMavenOutputParserDelegate.h"

#import "MBTaskRunnerDocument.h"

@interface MBTaskRunnerWindowController () <MBMavenOutputParserDelegate>

@property MBMavenTaskExecutor *executor;

@end

@implementation MBTaskRunnerWindowController

- (id)initWithOwner:(id)owner
{
	self = [super initWithWindowNibName:@"MBTaskRunnerDocument" owner:owner];
	if (self) {
		_executor = [[MBMavenTaskExecutor alloc] init];
		_executor.executionObserver = self;
	}
	return self;
}

- (void)windowDidLoad
{
	MBTaskRunnerDocument *document = [self document];
	NSString *directory = document.taskDefinition.directory;
	NSURL *directoryURL = [NSURL URLWithString:directory];
	
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
			NSArray *urls = [openPanel URLs];
			NSURL *url = [urls objectAtIndex:0];
			
			[self.pathControl setURL:url];
			
			MBTaskRunnerDocument *document = [self document];
			document.taskDefinition.directory = [url absoluteString];
		}
	}];
}

-(IBAction)startTask:(id)sender
{
	if ([self.executor isRunning]) {
		return;
	}
	
	NSString *args = [self.commandField stringValue];
	if ([args length] == 0) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText: @"Nelze spustit prázdný příkaz."];
		
		[alert beginSheetModalForWindow:[self window]
						  modalDelegate:nil
						 didEndSelector:NULL
							contextInfo:nil];
		return;
	}
	
	NSURL *path = [self.pathControl URL];
	[self.executor launchMavenWithArguments:args onPath:path];
}

-(IBAction)stopTask:(id)sender
{
	[self.executor terminate];
}

-(IBAction)revealFolderInFinder:(id)sender
{
	NSArray *fileURLs = @[self.pathControl.URL];
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:fileURLs];
}

#pragma mark - Observer methods -
-(void)task:(NSString *)executable willStartWithArguments:(NSString *)arguments onPath:(NSString *)projectDirectory
{
	[self.progressIndicator startAnimation:self];
	
	NSString *executionHeader = [NSString stringWithFormat:@"$ cd %@\n$ %@ %@\n\n",
								 projectDirectory,
								 executable,
								 arguments];
	[self.outputTextView setString:executionHeader];
	
	_taskRunning = YES;
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
		_taskRunning = NO;
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
