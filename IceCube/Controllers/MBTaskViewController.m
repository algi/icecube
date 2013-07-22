//
//  MBTaskViewController.m
//  IceCube
//
//  Created by Marian Bouček on 15.07.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBTaskViewController.h"
#import "MBMavenTaskExecutor.h"

#define kMavenWorkingDirectory @"maven.working.directory"

@interface MBTaskViewController () <MBMavenOutputParserDelegate>

@property MBMavenTaskExecutor *executor;

@end

@implementation MBTaskViewController

- (id)initWithWindow:(NSWindow *)window
{
	self = [super initWithWindow:window];
	if (self) {
		_executor = [[MBMavenTaskExecutor alloc] init];
		
		__weak id<MBMavenOutputParserDelegate> observer = self;
		_executor.executionObserver = observer;
	}
	return self;
}

- (void)windowDidLoad
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

-(IBAction)startTask:(id)sender
{
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
	
	[self.executor launchMavenWithArguments:args
									 onPath:path];
}

-(IBAction)stopTask:(id)sender
{
	[self.executor terminate];
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
