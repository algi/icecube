//
//  MBMavenServiceTask.m
//  IceCube
//
//  Created by Marian Bouček on 20.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBMavenServiceTask.h"

#import "MBMavenServiceCallback.h"

@implementation MBMavenServiceTask

- (void)launchMavenWithArguments:(NSString *)arguments
						  onPath:(NSURL *)path
{
	// TODO skutečně spustit task
	[[self.xpcConnection remoteObjectProxy] newLineDidRecieve:@"Hello from XPC!"];
}

@end
