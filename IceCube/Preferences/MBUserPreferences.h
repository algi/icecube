//
//  MBUserPreferences.h
//  IceCube
//
//  Created by Marian Bouček on 11.10.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBUserPreferences : NSObject

@property NSString *defaultJavaHome;
@property NSString *defaultMavenHome;

@property (readonly) NSString *javaHome;
@property (readonly) NSString *mavenHome;

+ (MBUserPreferences *)standardUserPreferences;

@end

@interface MBUserPreferences (MBUserPreferencesController)

- (NSString *)customJavaHome;
- (void)setCustomJavaHome:(NSString *)customJavaHome;

- (NSString *)customMavenHome;
- (void)setCustomMavenHome:(NSString *)customMavenHome;

@end
