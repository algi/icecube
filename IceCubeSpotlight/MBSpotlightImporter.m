//
//  MBSpotlightImporter.m
//  IceCube
//
//  Created by Marian Bouček on 06.04.17.
//  Copyright © 2017 Marian Bouček. All rights reserved.
//

#import "MBSpotlightImporter.h"

#import <os/log.h>

@implementation MBSpotlightImporter

+(NSString *)contentToIndexFromFile:(NSString *)pathToFile contentTypeUTI: (NSString *)contentTypeUTI
{
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:pathToFile options:0 error:&error];

    if (data == nil) {
        os_log_error(OS_LOG_DEFAULT, "MBSpotlightImporter - Unable to import file: %{public}@, error: %@", pathToFile, [error localizedDescription]);
        return nil;
    }

    NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
    id propertyList = [NSPropertyListSerialization propertyListWithData:data options:0 format:&format error:&error];

    if (propertyList == nil) {
        os_log_error(OS_LOG_DEFAULT, "MBSpotlightImporter - Unable to parse PLIST from file: %{public}@, error: %@", pathToFile, [error localizedDescription]);
        return nil;
    }

    NSString *contentToIndex = nil;
    if ([propertyList isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = propertyList;
        contentToIndex = dictionary[@"command"];
    }

    return contentToIndex;
}

@end
