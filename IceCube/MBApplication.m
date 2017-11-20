//
//  MBApplication.m
//  IceCube
//
//  Created by Marian Boucek on 27.09.14.
//  Copyright (c) 2014 Marian Bouček. All rights reserved.
//

#import "MBApplication.h"

#import "MBTaskRunnerDocument.h"
#import "MBTaskRunnerWindowController.h"
#import "MBPreferencesWindowController.h"
#import "MBRecoveryAttempter.h"

@implementation MBApplication

-(BOOL)isAutomaticCustomizeTouchBarMenuItemEnabled
{
    return YES;
}

-(NSError *)willPresentError:(NSError *)error
{
    return [MBRecoveryAttempter installRecoveryAttempterToErrorIfSupported:error];
}

#pragma mark - Scripting support -
- (NSArray<NSWindowController *> *)projects
{
    NSMutableArray<NSWindowController *> *result = [[NSMutableArray alloc] init];
    NSArray *orderedDocuments = [self orderedDocuments];

    for (MBTaskRunnerDocument *document in orderedDocuments) {
        for (NSWindowController *controller in [document windowControllers]) {
            if ([controller isKindOfClass:[MBTaskRunnerWindowController class]]) {
                [result addObject:controller];
            }
        }
    }

    return result;
}

-(NSURL *)javaHome
{
    return [[NSUserDefaults standardUserDefaults] URLForKey:kJavaHomeDefaultsKey];
}

-(void)setJavaHome:(NSURL *)javaHome
{
    [[NSUserDefaults standardUserDefaults] setURL:javaHome forKey:kJavaHomeDefaultsKey];
}

-(NSURL *)mavenHome
{
    return [[NSUserDefaults standardUserDefaults] URLForKey:kMavenHomeDefaultsKey];
}

-(void)setMavenHome:(NSURL *)mavenHome
{
    [[NSUserDefaults standardUserDefaults] setURL:mavenHome forKey:kMavenHomeDefaultsKey];
}

@end
