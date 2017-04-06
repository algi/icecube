//
//  GetMetadataForFile.m
//  IceCubeSpotlight
//
//  Created by Marian Bouček on 05.04.17.
//  Copyright © 2017 Marian Bouček. All rights reserved.
//

@import Foundation;

Boolean GetMetadataForFile(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile);

Boolean GetMetadataForFile(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile)
{
    @autoreleasepool {
        if ([(__bridge NSString *)contentTypeUTI isEqualToString:@"cz.boucekm.icecube-proj"]) {

            NSString *path = (__bridge NSString * _Nonnull)(pathToFile);

            NSError *error = nil;
            NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];

            if (data == nil) {
                NSLog(@"Unable to import file: %@, error: %@", path, [error localizedDescription]);
                return FALSE;
            }

            NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
            id propertyList = [NSPropertyListSerialization propertyListWithData:data options:0 format:&format error:&error];

            if (propertyList == nil) {
                NSLog(@"Unable to parse PLIST from file: %@, error: %@", path, [error localizedDescription]);
                return FALSE;
            }

            NSString *contentToIndex = nil;
            if ([propertyList isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dictionary = propertyList;
                contentToIndex = dictionary[@"command"];
            }

            if (contentToIndex) {
                ((__bridge NSMutableDictionary *)attributes)[(NSString *)kMDItemTextContent] = contentToIndex;
                return TRUE;
            }
            else {
                return FALSE;
            }
        }
    }

    return FALSE;
}
