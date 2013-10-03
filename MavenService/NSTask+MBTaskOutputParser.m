//
//  NSTask+MBTaskOutputParser.m
//  IceCube
//
//  Created by Marian Bouček on 17.07.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "NSTask+MBTaskOutputParser.h"

@implementation NSTask (MBTaskOutputParser)

- (BOOL)launchWithTaskOutputBlock:(void (^)(NSString *))delegateBlock error:(__autoreleasing NSError *)error
{
	id pipe = [NSPipe pipe];
	[self setStandardOutput:pipe];
	[self setStandardError:pipe];
	
	@try {
		[self launch];
	}
	@catch (NSException *exception) {
		error = [NSError errorWithDomain:exception.name
									code:1
								userInfo:@{NSLocalizedDescriptionKey: exception.reason}];
		return NO;
	}
	
	NSData *inData = nil;
	NSString *partialLinesBuffer = nil;
	NSFileHandle *fileHandle = [pipe fileHandleForReading];
	NSCharacterSet *characterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	
	while ((inData = [fileHandle availableData]) && [inData length]) {
		NSString *outputLine = [[NSString alloc] initWithData:inData encoding:[NSString defaultCStringEncoding]];
		NSArray *components = [outputLine componentsSeparatedByString:@"\n"];
		
		if (partialLinesBuffer) {
			// append partial line to the start of buffer
			NSString *firstObject = [components firstObject];
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
			
			NSString *line = [components[index] stringByTrimmingCharactersInSet:characterSet];
			if ([line length] == 0) {
				continue;
			}
			
			delegateBlock(line);
		}
	}
	
	// consume rest of partial lines
	if (partialLinesBuffer) {
		delegateBlock(partialLinesBuffer);
    }
	
	return YES;
}

@end
