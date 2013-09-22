//
//  main.m
//  JavaHomeService
//
//  Created by Marian Bouček on 22.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#include <xpc/xpc.h>
#include <Foundation/Foundation.h>

#import "MBJavaHomeService.h"
#import "MBJavaHomeServiceTask.h"

@interface MBJavaHomeServiceDelegate : NSObject <NSXPCListenerDelegate>
@end

@implementation MBJavaHomeServiceDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
	MBJavaHomeServiceTask *task = [[MBJavaHomeServiceTask alloc] init];
	
	newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MBJavaHomeService)];
	newConnection.exportedObject = task;
	
	[newConnection resume];
	return YES;
}

@end

int main(int argc, const char *argv[])
{
	MBJavaHomeServiceDelegate *delegate = [[MBJavaHomeServiceDelegate alloc] init];
	
	NSXPCListener *listener = [NSXPCListener serviceListener];
	listener.delegate = delegate;
	
	[listener resume];
	
	// The resume method never returns.
	exit(EXIT_FAILURE);
	return 0;
}
