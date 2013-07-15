//
//  MBTaskOutputReader.m
//  IceCube
//
//  Created by Marian Bouček on 01.04.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBTaskOutputReader.h"

@implementation MBTaskOutputReader

#if NS_BLOCKS_AVAILABLE
+ (void)launchTask:(NSTask *)task withOutputConsumer: (void (^)(NSString* line)) consumeOutput
{
	id pipe = [NSPipe pipe];
	[task setStandardOutput:pipe];
	[task setStandardError:pipe];
	
	NSFileHandle *fileHandle = [pipe fileHandleForReading];
	[task launch];
	
	NSData *inData = nil;
	NSString *partialLinesBuffer = nil;
	NSCharacterSet *characterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	
	while ((inData = [fileHandle availableData]) && [inData length]) {
		NSString *outputLine = [[NSString alloc] initWithData:inData encoding:[NSString defaultCStringEncoding]];
		NSArray *components = [outputLine componentsSeparatedByString:@"\n"];
		
		if (partialLinesBuffer) {
			// append partial line to the start of buffer
			NSString *firstObject = [components objectAtIndex:0];
			NSString *fullLine = [partialLinesBuffer stringByAppendingString:firstObject];
			
			NSMutableArray *mutableCopy = [components mutableCopy];
			[mutableCopy setObject:fullLine atIndexedSubscript:0];
			
			components = mutableCopy;
			partialLinesBuffer = nil;
		}
		
		NSInteger linesCount = [components count];
		
		// if last component doesn't have newline
		// append it to partial line buffer and then skip it
		NSString *lastComponent = [components lastObject];
		if (![lastComponent hasSuffix:@"\n"]) {
			partialLinesBuffer = [lastComponent copy];
			linesCount--;
		}
		
		NSUInteger index;
		for (index = 0; index < linesCount; index++) {
			
			NSString *line = [[components objectAtIndex:index] stringByTrimmingCharactersInSet:characterSet];
			if ([line length] == 0) {
				continue;
			}
			
			consumeOutput(line);
		}
	}
	
	// consume rest of partial lines
	if (partialLinesBuffer) {
		consumeOutput(partialLinesBuffer);
    }
}
#endif

@end
