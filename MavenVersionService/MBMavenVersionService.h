//
//  MavenVersionServiceProtocol.h
//  MavenVersionService
//
//  Created by Marian Bouček on 13.04.17.
//  Copyright © 2017 Marian Bouček. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN
@protocol MBMavenVersionService

- (void)readVersionInformationWithMaven:(NSString *)launchPath
                            environment:(NSDictionary *)environment
                       currentDirectory:(NSURL *)currentDirectory
                               callback:(void(^)(NSString *, NSString *))callback; // Maven version, Java version
    
@end
NS_ASSUME_NONNULL_END
