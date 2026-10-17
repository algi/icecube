//
//  MBMavenVersionInfo.h
//  MavenVersionService
//
//  Created by Marian Bouček on 17.10.2026.
//  Copyright © 2026 Marian Bouček. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MBMavenVersionInfo : NSObject<NSSecureCoding>

@property(nonatomic, copy) NSString *javaVersion;
@property(nonatomic, copy) NSString *mavenVersion;

- (instancetype)initWithJavaVersion:(NSString *) javaVersion mavenVersion:(NSString *) mavenVersion;

@end

NS_ASSUME_NONNULL_END
