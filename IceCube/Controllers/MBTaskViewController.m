//
//  MBTaskViewController.m
//  IceCube
//
//  Created by Marian Bouček on 15.07.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBTaskViewController.h"

#import "MBMavenTaskExecutor.h"

@interface MBTaskViewController () <MBMavenOutputParserDelegate>

@property MBMavenTaskExecutor *executor;

@end

@implementation MBTaskViewController

-(id)init
{
	self = [super init];
	
	if (self) {
		_executor = [[MBMavenTaskExecutor alloc] init];
		
		__weak id<MBMavenOutputParserDelegate> observer = self;
		_executor.executionObserver = observer;
	}
	
	return self;
}

-(IBAction)startTask:(id)sender
{
	NSString *args = [self.commandField stringValue];
	NSURL *path = [self.pathControl URL];
	
	[self.executor launchMavenWithArguments:args onPath:path];
}

-(IBAction)stopTask:(id)sender
{
	[self.executor terminate];
}

#pragma mark - Observer methods -
-(void)buildDidStartWithTaskList:(NSArray *)taskList
{
	dispatch_async(dispatch_get_main_queue(), ^{
		// ...
	});
}

-(void)buildDidEndSuccessfully:(BOOL)result
{
	dispatch_async(dispatch_get_main_queue(), ^{
		// ...
	});
}

-(void)projectDidStartWithName:(NSString *)name
{
	dispatch_async(dispatch_get_main_queue(), ^{
		// ...
	});
}

-(void)newLineDidRecieve:(NSString *)line
{
	dispatch_async(dispatch_get_main_queue(), ^{
		NSTextStorage *storage = [self.outputTextView textStorage];
		NSDictionary *attributes = [storage attributesAtIndex:0 effectiveRange:nil];
		
		[storage beginEditing];
		[storage appendAttributedString:[[NSAttributedString alloc] initWithString:[line stringByAppendingString:@"\n"]
																		attributes:attributes]];
		[storage endEditing];
		
		[self.outputTextView scrollRangeToVisible:NSMakeRange([[self.outputTextView string] length], 0)];
	});
}

@end
