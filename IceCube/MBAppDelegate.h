//
//  MBAppDelegate.h
//  IceCube
//
//  Created by Marian Bouček on 14.12.12.
//  Copyright (c) 2012 Marian Bouček. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kMavenWorkingDirectory @"maven.working.directory"

@interface MBAppDelegate : NSObject <NSApplicationDelegate>

@property (atomic) NSTask *task;

#pragma mark - Main window -
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *commandField;
@property (assign) IBOutlet NSPathControl *pathControll;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;

@property (assign) IBOutlet NSToolbarItem *runTaskButton;
@property (assign) IBOutlet NSToolbarItem *stopTaskButton;

@property (assign) IBOutlet NSTextView *outputTextView;

#pragma mark - Actions -
- (IBAction)runAction:(id)sender;
- (IBAction)stopAction:(id)sender;

#pragma mark - CoreData stack -
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end