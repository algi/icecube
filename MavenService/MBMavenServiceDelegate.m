//
//  MBMavenServiceDelegate.m
//  IceCube
//
//  Created by Marian Bouček on 19.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBMavenServiceDelegate.h"

#import "MBMavenServiceTask.h"
#import "MBMavenServiceCallback.h"

@implementation MBMavenServiceDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
	MBMavenServiceTask *task = [[MBMavenServiceTask alloc] init];
	task.xpcConnection = newConnection;
	
	newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MBMavenService)];
	newConnection.exportedObject = task;
	
	newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MBMavenServiceCallback)];
	
	[newConnection resume];
	return YES;
}

@end
