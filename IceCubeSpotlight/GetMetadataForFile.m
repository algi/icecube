//
//  GetMetadataForFile.m
//  IceCubeSpotlight
//
//  Created by Marian Bouček on 05.04.17.
//  Copyright © 2017 Marian Bouček. All rights reserved.
//

@import Foundation;

#import "MBSpotlightImporter.h"

Boolean GetMetadataForFile(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile);

Boolean GetMetadataForFile(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile)
{
    @autoreleasepool {

        NSString *filePath = (__bridge NSString * _Nonnull)(pathToFile);
        NSString *contentType = (__bridge NSString * _Nonnull)(contentTypeUTI);

        if (![contentType isEqualToString:@"cz.boucekm.icecube-proj"]) {
            return FALSE;
        }

        NSString* contentToIndex = [MBSpotlightImporter contentToIndexFromFile:filePath contentTypeUTI:contentType];

        if (contentToIndex) {
            ((__bridge NSMutableDictionary *)attributes)[(NSString *)kMDItemTextContent] = contentToIndex;
            return TRUE;
        }
        else {
            return FALSE;
        }
    }
}
