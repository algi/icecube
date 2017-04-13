//
//  MBPreferencesRecoveryAttempter.m
//  IceCube
//
//  Created by Marian Bouček on 13.04.17.
//  Copyright © 2017 Marian Bouček. All rights reserved.
//

#import "MBRecoveryAttempter.h"

#import "MBErrorDomain.h"
#import <os/log.h>

@implementation MBRecoveryAttempter

+ (NSError *)installRecoveryAttempterToErrorIfSupported:(NSError *)error
{
    // we need to add our recovery attempter, since the error comes from XPC service
    if ([MBRecoveryAttempter isErrorSupported:error]) {

        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
        userInfo[NSRecoveryAttempterErrorKey] = [[MBRecoveryAttempter alloc] init];

        return [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
    }

    return error;
}

+ (BOOL)isErrorSupported:(NSError *)error
{
    return [error.domain isEqualToString:IceCubeDomain] &&
            (error.code == kIceCube_unableToFindJavaHomeError || error.code == kIceCube_unableToLaunchMavenError);
}

#pragma mark - NSErrorRecoveryAttempting -

- (void)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex delegate:(nullable id)delegate didRecoverSelector:(nullable SEL)didRecoverSelector contextInfo:(nullable void *)contextInfo
{
    BOOL result = [self attemptRecoveryFromError:error optionIndex:recoveryOptionIndex];

    // didRecoverSelector should be: - (void)didPresentErrorWithRecovery:(BOOL)didRecover contextInfo:(void *)contextInfo;
    if (delegate && didRecoverSelector) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [delegate performSelector:didRecoverSelector withObject:@(result) withObject:(__bridge id)(contextInfo)];
#pragma clang diagnostic pop
    }
}

- (BOOL)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex
{
    if (recoveryOptionIndex == 0) {
        [self showPreferencesWindow:self];
    }

    return YES;
}

// this method name is intentionally same as selector's name in order to silence compiler warning
- (void)showPreferencesWindow:(id)sender
{
    // will send the message to MBAppDelegate
    [[NSApplication sharedApplication] sendAction:@selector(showPreferencesWindow:) to:nil from:sender];
}

@end
