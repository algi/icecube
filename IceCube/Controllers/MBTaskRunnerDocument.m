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

-(id)initWithType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
	self = [super initWithType:typeName error:outError];
	if (self) {
		NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
		_workingDirectory = [NSURL fileURLWithPath:documentDirectory isDirectory:YES];
		_command = nil;
	}
	return self;
}

- (void)makeWindowControllers
{
	MBTaskRunnerWindowController *controller = [[MBTaskRunnerWindowController alloc] init];
	[self addWindowController:controller];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:url];
	if (!dict) {
		*outError = MBValidationErrorWithMessage(@"Unable to read contents of file.");
		return NO;
	}
	
	NSString *directory = dict[@"directory"];
	if (![directory isAbsolutePath]) {
		*outError = MBValidationErrorWithMessage(@"Unable to read Maven working directory.");
		return NO;
	}
	self.workingDirectory = [NSURL fileURLWithPath:directory isDirectory:YES];
	
	NSString *command = dict[@"command"];
	if ([command length] <= 0) {
		*outError = MBValidationErrorWithMessage(@"Unable to read Maven command.");
		return NO;
	}
	self.command = command;
	
	return YES;
}

- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
	NSString *path = [self.workingDirectory path];
	if ([path length] <= 0) {
		*outError = MBValidationErrorWithMessage(@"Maven working path must be specified.");
		return NO;
	}
	
	NSString *command = self.command;
	if ([command length] <= 0) {
		command = @"";
	}
	
	NSDictionary *dict = @{@"directory": path,
						   @"command":   command};
	
	return [dict writeToURL:url atomically:YES];
}

// TODO window controller don't know about changes in document - what's wrong?
+ (BOOL)autosavesInPlace
{
    return YES; // TODO tohle na to (zatím) nemá vliv
}

#pragma mark - NSError helper -
NSError* MBValidationErrorWithMessage(NSString *message)
{
	return [NSError errorWithDomain:@"IceCube"
							   code:1
						   userInfo:@{NSLocalizedDescriptionKey:message}];
}

@end
