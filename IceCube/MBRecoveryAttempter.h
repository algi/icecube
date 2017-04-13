//
//  MBPreferencesRecoveryAttempter.h
//  IceCube
//
//  Created by Marian Bouček on 13.04.17.
//  Copyright © 2017 Marian Bouček. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBRecoveryAttempter : NSObject

+ (NSError *)installRecoveryAttempterToErrorIfSupported:(NSError *)error;

@end
