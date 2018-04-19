//
//  MBMavenService.m
//  IceCube
//
//  Created by Marian Bouček on 17.04.18.
//  Copyright © 2018 Marian Bouček. All rights reserved.
//

#import "MBServiceProvider.h"

#import <os/log.h>

@implementation MBServiceProvider

- (void) runAsMavenCommand:(NSPasteboard *)pasteboard
                  userData:(NSString *)userData
                     error:(NSString * __autoreleasing *)error
{
    NSString *selectedFileName = [[pasteboard propertyListForType:NSFilenamesPboardType] firstObject];
    os_log_info(OS_LOG_DEFAULT, "Invoke runAsMavenCommand with URL: %@", selectedFileName);

    // TODO: create new document with path
}

@end
