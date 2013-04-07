//
//  MBTaskOutputReader.h
//  IceCube
//
//  Created by Marian Bouček on 01.04.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBTaskOutputReader : NSObject

#if NS_BLOCKS_AVAILABLE
/**
 Spustí úlohu na aktuálním vlákně. Předpokládá, že úloha je již správně nastavena.
 
 @param task úloha
 @param outputConsumer vlastní zpracování výstupních řádků
 */
+ (void)launchTask:(NSTask *)task withOutputConsumer: (void (^)(NSString* line)) outputConsumer;
#endif

@end
