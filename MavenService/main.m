//
//  main.m
//  MavenService
//
//  Created by Marian Bouček on 19.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

@import XPC;

#import "MBMavenServiceTask.h"
#import "MBMavenServiceCallback.h"

@interface MBMavenServiceDelegate : NSObject <NSXPCListenerDelegate>
@end

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

int main(int argc, const char *argv[])
{
    MBMavenServiceDelegate *delegate = [[MBMavenServiceDelegate alloc] init];

    NSXPCListener *listener = [NSXPCListener serviceListener];
    listener.delegate = delegate;

    [listener resume];

    // The resume method never returns.
    exit(EXIT_FAILURE);
}
