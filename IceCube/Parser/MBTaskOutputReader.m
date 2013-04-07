//
//  MBTaskOutputReader.m
//  IceCube
//
//  Created by Marian Bouček on 01.04.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBTaskOutputReader.h"

@implementation MBTaskOutputReader

// TODO bufferování + rozdělování na řádky
#if NS_BLOCKS_AVAILABLE
+ (void)launchTask:(NSTask *)task withOutputConsumer: (void (^)(NSString* line)) consumeOutput
{
	id pipe = [NSPipe pipe];
	[task setStandardOutput:pipe];
	[task setStandardError:pipe];
	
	NSFileHandle *fileHandle = [pipe fileHandleForReading];
	[task launch];
	
	NSData *inData = nil;
	NSString *buffer = nil; // buffer pro neúplné řádky
	
	while ((inData = [fileHandle availableData]) && [inData length]) {
		NSString *outputLine = [[NSString alloc] initWithData:inData encoding:[NSString defaultCStringEncoding]];
		NSArray *components = [outputLine componentsSeparatedByString:@"\n"];
		
		if (buffer) {
			// od minula máme něco v bufferu, takže to připojíme k první komponentě
			NSString *firstObject = [components objectAtIndex:0];
			NSString *fullLine = [buffer stringByAppendingString:firstObject];
			
			NSMutableArray *mutableCopy = [components mutableCopy];
			[mutableCopy setObject:fullLine atIndexedSubscript:0];
			
			components = mutableCopy;
			buffer = nil;
		}
		
		NSInteger size = [components count];
		
		if (![outputLine hasSuffix:@"\n"]) {
			// neúplně načtený řádek, bude nutno zpracovat později
			buffer = [components lastObject];
			size--;
		}
		
		NSInteger index;
		for (index = 0; index < size; index++) {
			
			// ořízní konce řádků a podobné nesmysly
			NSString *line = [[components objectAtIndex:index] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			
			// prázdné řádky ignoruj
			if ([line length] == 0) {
				continue;
			}
			
			consumeOutput(line);
		}
	}
	
	if (buffer) {
		// něco ještě zbylo v bufferu, zpracovat
		consumeOutput(buffer);
		buffer = nil;
	}
}
#endif

@end
