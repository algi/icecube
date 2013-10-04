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
	
	// create arguments for CommandLine and specified version
	NSMutableArray *arguments = [self createCommonArguments];
	if (version != nil) {
		[arguments addObject:@"--version"];
		[arguments addObject:version];
	}
	[task setArguments:arguments];
	
	// setup output pipe and launch task
	NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
	
	@try {
		[task launch];
	}
	@catch (NSException *exception) {
		NSLog(@"Cannot launch task for reason: %@", [exception reason]);
		exit(-1);
	}
	
	NSData *inData = nil;
	NSFileHandle *fileHandle = [outputPipe fileHandleForReading];
	
	NSString *outputLine = nil;
	while ((inData = [fileHandle availableData]) && [inData length]) {
		
		// second line is empty
		if (outputLine) {
			continue;
		}
		
		outputLine = [[[NSString alloc] initWithData:inData encoding:[NSString defaultCStringEncoding]]
										stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	}
	
	reply(outputLine);
	exit(0);
}

- (void)findAvaliableJavaVirtualMachinesWithReply:(void(^)(NSArray *machines))reply
{
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/libexec/java_home"];
	
	NSMutableArray *arguments = [self createCommonArguments];
	[arguments addObject:@"-V"];
	[task setArguments:arguments];
		
	// setup output pipe and launch task
	NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
	
	NSPipe *errorPipe = [NSPipe pipe];
	[task setStandardError:errorPipe];
	
	@try {
		[task launch];
	}
	@catch (NSException *exception) {
		NSLog(@"Cannot launch task for reason: %@", [exception reason]);
		exit(-1);
	}
	
	NSArray *outputLines = [self readFileHandle:[outputPipe fileHandleForReading]];
	NSArray *errorLines = [self readFileHandle:[errorPipe fileHandleForReading]];
	
	NSArray *result = [outputLines arrayByAddingObjectsFromArray:errorLines];
	
	reply(result);
	exit(0);
}

- (NSMutableArray *)createCommonArguments
{
	NSMutableArray *arguments = [[NSMutableArray alloc] init];
	
	[arguments addObject:@"--task"];
	[arguments addObject:@"CommandLine"];
	
	return arguments;
}

- (NSArray *)readFileHandle:(NSFileHandle *)fileHandle
{
	NSMutableArray *outputLines = [[NSMutableArray alloc] init];
	
	NSData *inData = nil;
	while ((inData = [fileHandle availableData]) && [inData length]) {
		NSString *outputLine = [[NSString alloc] initWithData:inData encoding:[NSString defaultCStringEncoding]];
		[outputLines addObject:outputLine];
	}
	
	return outputLines;
}

@end
