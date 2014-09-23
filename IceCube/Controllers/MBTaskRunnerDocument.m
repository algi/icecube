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

- (id)initWithType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
	self = [super initWithType:typeName error:outError];
	if (self) {
		NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
		_workingDirectory = [NSURL fileURLWithPath:documentDirectory isDirectory:YES];
		_command = @"";
	}
	return self;
}

#pragma mark - NSUndoManager support -
- (void)setCommand:(NSString *)command
{
    NSString *oldValue = _command;
    _command = command;

    [[self undoManager] registerUndoWithTarget:self selector:@selector(setCommand:) object:oldValue];
    [[self undoManager] setActionName:NSLocalizedString(@"Typing", @"Undo action for setting new value for command.")];
}

- (void)setWorkingDirectory:(NSURL *)workingDirectory
{
    NSURL *oldValue = _workingDirectory;
    _workingDirectory = workingDirectory;

    [[self undoManager] registerUndoWithTarget:self selector:@selector(setWorkingDirectory:) object:oldValue];
    [[self undoManager] setActionName:NSLocalizedString(@"Set Working Directory", @"Undo action for setting new working directory.")];
}

#pragma mark - NSDocument -
- (void)makeWindowControllers
{
	MBTaskRunnerWindowController *controller = [[MBTaskRunnerWindowController alloc] init];
	[self addWindowController:controller];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
    id root = [NSPropertyListSerialization propertyListWithData:data options:0 format:&format error:outError];
    if (!root) {
        // pass already filled NSError
        return NO;
    }

    if (![root isKindOfClass:[NSDictionary class]]) {
        *outError = MBValidationErrorWithMessage(@"Document content is corrupted and cannot be read.");
        return NO;
    }
    NSDictionary *dictionary = root;

    NSString *directory = dictionary[@"directory"];
    if (![directory isAbsolutePath]) {
        *outError = MBValidationErrorWithMessage(@"Unable to read Maven working directory.");
        return NO;
    }
    _workingDirectory = [NSURL fileURLWithPath:directory isDirectory:YES];

    NSString *command = dictionary[@"command"];
    if (!command) {
        command = @"";
    }
    _command = command;

    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    NSString *path = [self.workingDirectory path];
    NSString *command = self.command;

    NSDictionary *outputDictionary = @{@"directory": path,
                                       @"command":   command};

    return [NSPropertyListSerialization dataWithPropertyList:outputDictionary
                                                      format:NSPropertyListXMLFormat_v1_0
                                                     options:0
                                                       error:outError];
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

#pragma mark - NSError helper -
NSError* MBValidationErrorWithMessage(NSString *message)
{
	return [NSError errorWithDomain:@"IceCube"
							   code:1
						   userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(message, message)}];
}

@end
