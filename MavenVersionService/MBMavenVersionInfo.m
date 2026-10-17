//
//  MBMavenVersionInfo.m
//  MavenVersionService
//
//  Created by Marian Bouček on 17.10.2026.
//  Copyright © 2026 Marian Bouček. All rights reserved.
//

#import "MBMavenVersionInfo.h"

// note: this class is also included in the main app bundle
@implementation MBMavenVersionInfo

- (instancetype)initWithJavaVersion:(NSString *) javaVersion mavenVersion:(NSString *) mavenVersion
{
    self = [super init];
    if (self) {
        _javaVersion = javaVersion;
        _mavenVersion = mavenVersion;
    }
    return self;
}

#pragma mark - NSSecureCoding -

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder
{
    self = [super init];
    if (self) {
        _javaVersion = [coder decodeObjectOfClass:[NSString class] forKey:@"java_version"];
        _mavenVersion = [coder decodeObjectOfClass:[NSString class] forKey:@"maven_version"];
    }
    return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder
{
    [coder encodeObject:self.javaVersion forKey:@"java_version"];
    [coder encodeObject:self.mavenVersion forKey:@"maven_version"];
}

@end
