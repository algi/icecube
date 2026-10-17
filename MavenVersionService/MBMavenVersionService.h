//
//  MavenVersionServiceProtocol.h
//  MavenVersionService
//
//  Created by Marian Bouček on 13.04.17.
//  Copyright © 2017 Marian Bouček. All rights reserved.
//

@import Foundation;

#import "MBMavenVersionInfo.h"

NS_ASSUME_NONNULL_BEGIN
@protocol MBMavenVersionService

- (void)readVersionInformationWithMaven:(NSString *)launchPath
                            environment:(NSDictionary *)environment
                               callback:(void(^)(MBMavenVersionInfo *))callback;

@end
NS_ASSUME_NONNULL_END
