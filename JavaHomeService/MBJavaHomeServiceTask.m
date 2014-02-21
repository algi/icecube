//
//  MBJavaHomeServiceTask.m
//  IceCube
//
//  Created by Marian Bouček on 22.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBJavaHomeServiceTask.h"

@implementation MBJavaHomeServiceTask

- (void)findDefaultJavaHome:(void(^)(NSString *result, NSError *error))reply
{
	NSTask *task = [[NSTask alloc] init];
	
	[task setLaunchPath:@"/usr/libexec/java_home"];
	[task setArguments:@[@"--task", @"CommandLine"]];
	
	NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
	
	NSFileHandle *fileHandle = [outputPipe fileHandleForReading];
	
	@try {
		[task launch];
	}
	@catch (NSException *exception) {
		NSError *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{NSLocalizedDescriptionKey: @""}];
		reply(nil, error);
		return;
	}
	
	NSData *inData = nil;
	NSString *outputLine = nil;
	
	while ((inData = [fileHandle availableData]) && [inData length]) {
		
		// second line is empty
		if (outputLine) {
			continue;
		}
		
		outputLine = [[[NSString alloc] initWithData:inData encoding:[NSString defaultCStringEncoding]]
										stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	}
	
	reply(outputLine, nil);
	
	// we can exit now because there is no need to hold process anymore
	exit(EXIT_SUCCESS);
}

@end
