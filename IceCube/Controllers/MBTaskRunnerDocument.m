//
//  MBTaskRunnerDocument.m
//  IceCube
//
//  Created by Marian Bouček on 18.08.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBTaskRunnerDocument.h"

#import "MBTaskRunnerWindowController.h"

@implementation MBTaskRunnerDocument

- (id)init
{
	if (self = [super init]) {
		[self readContentOfFile];
	}
	return self;
}

- (void)makeWindowControllers
{
	MBTaskRunnerWindowController *controller = [[MBTaskRunnerWindowController alloc] init];
	[self addWindowController:controller];
}

- (void)readContentOfFile
{
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[Task entityName]
														 inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entityDescription];
	
	NSError *error;
	NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	if (fetchedObjects == nil) {
		[NSApp presentError:error];
		return;
	}
	
	Task *taskDefinition;
	if ([fetchedObjects count] == 0) {
		taskDefinition = [NSEntityDescription insertNewObjectForEntityForName:[Task entityName]
													   inManagedObjectContext:self.managedObjectContext];
		
		NSString *directory = [NSString stringWithFormat:@"file://localhost%@", NSHomeDirectory()];
		taskDefinition.directory = directory;
		
		[self.undoManager removeAllActions];
	}
	else {
		taskDefinition = fetchedObjects[0];
	}
	
	_taskDefinition = taskDefinition;
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

@end
