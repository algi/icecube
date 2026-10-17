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
    newConnection.exportedObject = [[MBMavenVersionServiceTask alloc] init];

    [newConnection setCodeSigningRequirement:@"anchor apple generic "
                                             @"and identifier cz.boucekm.IceCube "
                                             @"and certificate leaf[subject.OU] = \"72CQ273HEW\""];

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
