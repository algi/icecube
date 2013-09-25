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

#pragma mark - Task preparation -
- (NSString *)launchPath:(__autoreleasing NSError **)error
{
	NSString *launchPath = [[NSUserDefaults standardUserDefaults] stringForKey:kMavenApplicationPath];
	if (launchPath) {
		if ([self isPathAccessible:launchPath]) {
			return launchPath;
		}
		else {
			if (error != NULL) {
				*error = [NSError errorWithDomain:@"MBMavenNotFound"
											 code:1
										 userInfo:@{NSLocalizedDescriptionKey: @"Maven path is not accesible."}];
			}
			return nil;
		}
	}
	
	NSString *defaultLaunchPath = @"/usr/bin/mvn";
	if ([self isPathAccessible:defaultLaunchPath]) {
		return defaultLaunchPath;
	}
	else {
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"MBMavenNotFound"
										 code:2
									 userInfo:@{NSLocalizedDescriptionKey: @"Maven not found."}];
		}
		return nil;
	}
}

- (NSDictionary *)environment:(__autoreleasing NSError **)error
{
	NSString *javaHomeValue = [[NSUserDefaults standardUserDefaults] objectForKey:kJavaHomePath];
	if (javaHomeValue) {
		if ([self isPathAccessible:javaHomeValue]) {
			return @{@"JAVA_HOME": javaHomeValue};
		}
		else {
			if (error != NULL) {
				*error = [NSError errorWithDomain:@"MBJavaHomeNotFound"
											 code:1
										 userInfo:@{NSLocalizedDescriptionKey: @"JAVA_HOME is not accesible."}];
			}
			return nil;
		}
	}
	else {
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"MBJavaHomeNotFound"
										 code:2
									 userInfo:@{NSLocalizedDescriptionKey: @"Unable to determine JAVA_HOME."}];
		}
		return nil;
	}
}

- (BOOL)isPathAccessible:(NSString *)path
{
	return [[NSFileManager defaultManager] fileExistsAtPath:path]; // TODO and executable
}

@end
