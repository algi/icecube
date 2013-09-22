//
//  MBPreferencesWindowController.m
//  IceCube
//
//  Created by Marian Bouček on 22.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBPreferencesWindowController.h"

#import "MBJavaHomeService.h"

@interface MBPreferencesWindowController ()

@end

@implementation MBPreferencesWindowController

- (id)init
{
    self = [super initWithWindowNibName:@"MBPreferencesWindowController"];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (NSString *)defaultMavenPath
{
	return nil;
}

- (void)updateJavaPathForVersion:(NSString *)version
{
	NSXPCConnection *connection = [[NSXPCConnection alloc] initWithServiceName:@"cz.boucekm.JavaHomeService"];
	connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MBJavaHomeService)];
	
	[connection resume];
	
	[[connection remoteObjectProxy] findJavaLocationForVersion:version withReply:^(NSString *result) {
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			NSLog(@"Fetched result is: %@", result);
		}];
				
		[connection invalidate];
	}];
}

@end
