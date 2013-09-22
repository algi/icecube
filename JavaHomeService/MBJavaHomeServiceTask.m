//
//  MBJavaHomeServiceTask.m
//  IceCube
//
//  Created by Marian Bouček on 22.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBJavaHomeServiceTask.h"

@implementation MBJavaHomeServiceTask

- (void)findJavaLocationForVersion:(NSString *)version
						 withReply:(void(^)(NSString *result))reply
{
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/libexec/java_home"];
	
	NSArray *arguments = [self createArgumentsFromVersion:version];
	[task setArguments:arguments];
	
	NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
	
	[task launch];
	
	NSData *inData = nil;
	NSFileHandle *fileHandle = [outputPipe fileHandleForReading];
	
	NSString *outputLine = nil;
	while ((inData = [fileHandle availableData]) && [inData length]) {
		
		// second line is empty
		if (outputLine) {
			continue;
		}
		
		outputLine = [[NSString alloc] initWithData:inData encoding:[NSString defaultCStringEncoding]];
	}
	
	reply(outputLine);
	exit(0);
}

- (NSArray *)createArgumentsFromVersion:(NSString *)version
{
	NSMutableArray *arguments = [[NSMutableArray alloc] init];
	
	// we are interested only in command line apps (such as Maven)
	[arguments addObject:@"--task"];
	[arguments addObject:@"CommandLine"];
	
	// add version if specified
	if (version != nil) {
		[arguments addObject:@"--version"];
		[arguments addObject:version];
	}
	
	return arguments;
}

@end
