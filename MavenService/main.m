//
//  main.m
//  MavenService
//
//  Created by Marian Bouček on 19.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#include <xpc/xpc.h>
#include <Foundation/Foundation.h>

#import "MBMavenServiceDelegate.h"

int main(int argc, const char *argv[])
{
	MBMavenServiceDelegate *delegate = [[MBMavenServiceDelegate alloc] init];
	
	NSXPCListener *listener = [NSXPCListener serviceListener];
	listener.delegate = delegate;
	
	[listener resume];
	
	// The resume method never returns.
	exit(EXIT_FAILURE);
	return 0;
}
