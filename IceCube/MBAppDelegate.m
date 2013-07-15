//
//  MBAppDelegate.m
//  IceCube
//
//  Created by Marian Bouček on 14.12.12.
//  Copyright (c) 2012 Marian Bouček. All rights reserved.
//

#import "MBAppDelegate.h"

#import "MBTaskOutputReader.h"
#import "MBMavenOutputParser.h"

@implementation MBAppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
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
	
	[[NSNotificationCenter defaultCenter] addObserver:nil selector:nil name:kMavenNotifiactionBuildDidEnd object:nil];
}

-(void)awakeFromNib
{
	[super awakeFromNib];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	// prozatím máme jenom jedno okno, takže po sobě hezky uklidíme
    return YES;
}

// TODO je to docela prasárna mít tyhle věci v NSApplicationDelegate a ne v NSWindowController
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
	
	id pipe = [NSPipe pipe];
	[self.task setStandardOutput:pipe];
	[self.task setStandardError:pipe];
	
	[self taskDidStartInDirectory:path withApplication:launchPath command:command];
	
	// spuštění úlohy ve novém vlákně (normální priorita)
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
	dispatch_async(queue, ^{
		
		MBMavenOutputParser *parser = [[MBMavenOutputParser alloc] init];
		[MBTaskOutputReader launchTask:self.task withOutputConsumer:^(NSString *line) {
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

- (void)taskDidStartInDirectory: (NSString *)projectDirectory
				withApplication: (NSString *)appPath
						command: (NSString *)mavenCommand
{
	[self.progressIndicator startAnimation:self];
	
	NSString *command = [NSString stringWithFormat:@"$ cd %@\n$ %@ %@\n\n", projectDirectory, appPath, mavenCommand];
	[self.outputTextView setString:command];
}

// z parseru
-(void)buildDidEnd:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];
	BOOL result = [userInfo objectForKey:kMavenNotifiactionBuildDidEnd_result];
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

- (IBAction)stopAction:(id)sender
{
	[self.task terminate]; // SIGTERM
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

#pragma mark - CoreData stack -
// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "cz.boucekm.IceCube" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"cz.boucekm.IceCube"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"IceCube" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"IceCube.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) 
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

@end
