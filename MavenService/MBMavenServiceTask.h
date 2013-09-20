//
//  MBMavenServiceTask.h
//  IceCube
//
//  Created by Marian Bouček on 20.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MBMavenService.h"

@interface MBMavenServiceTask : NSObject <MBMavenService>

@property (weak) NSXPCConnection *xpcConnection;

@end
