//
//  MBSpotlightImporter.h
//  IceCube
//
//  Created by Marian Bouček on 06.04.17.
//  Copyright © 2017 Marian Bouček. All rights reserved.
//

@import Foundation;

@interface MBSpotlightImporter : NSObject

+(NSString *)contentToIndexFromFile:(NSString *)pathToFile contentTypeUTI: (NSString *)contentTypeUTI;

@end
