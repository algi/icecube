//
//  main.m
//  MavenVersionService
//
//  Created by Marian Bouček on 13.04.17.
//  Copyright © 2017 Marian Bouček. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MBMavenVersionService.h"
#import "MBMavenVersionServiceTask.h"

@interface MBServiceDelegate : NSObject <NSXPCListenerDelegate>
@end

@implementation MBServiceDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MBMavenVersionService)];

    MBMavenVersionServiceTask *exportedObject = [[MBMavenVersionServiceTask alloc] init];
    newConnection.exportedObject = exportedObject;

    [newConnection resume];
    return YES;
}

@end

int main(int argc, const char *argv[])
{
    MBServiceDelegate *delegate = [[MBServiceDelegate alloc] init];
    
    NSXPCListener *listener = [NSXPCListener serviceListener];
    listener.delegate = delegate;
    
    [listener resume];
    return 0;
}
