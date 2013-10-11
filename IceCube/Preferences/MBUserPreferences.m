//
//  MBUserPreferences.m
//  IceCube
//
//  Created by Marian Bouček on 11.10.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBUserPreferences.h"

// static NSString * const kMavenApplicationPath = @"maven.application.path";
// static NSString * const kJavaHomePath = @"java.home.path";

static NSString * const kMavenPopUpSelectedTagPreferencesKey = @"maven.popup.tag";
static NSString * const kMavenCustomHomePreferencesKey = @"maven.custom.home";

static NSString * const kJavaPopUpSelectedTagPreferencesKey = @"java.popup.tag";
static NSString * const kJavaCustomHomePreferencesKey = @"java.custom.home";

@implementation MBUserPreferences

+ (MBUserPreferences *)standardUserPreferences
{
	static MBUserPreferences *sharedInstance = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[MBUserPreferences alloc] init];
	});
	
	return sharedInstance;
}

#pragma mark - Custom readonly accessors -
- (NSString *)javaHome
{
	if ([self shouldReturnDefaultValueForTagKey:kJavaPopUpSelectedTagPreferencesKey]) {
		return self.defaultJavaHome;
	}
	else {
		return [self customJavaHome];
	}
}

- (NSString *)mavenHome
{
	if ([self shouldReturnDefaultValueForTagKey:kMavenPopUpSelectedTagPreferencesKey]) {
		return self.defaultMavenHome;
	}
	else {
		return [self customMavenHome];
	}
}

- (BOOL)shouldReturnDefaultValueForTagKey:(NSString *)tagKey
{
	NSInteger selectedTag = [[NSUserDefaults standardUserDefaults] integerForKey:tagKey];
	return selectedTag == 0;
}

#pragma mark - MBUserPreferencesController category -
- (NSString *)customJavaHome
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:kJavaCustomHomePreferencesKey];
}

- (void)setCustomJavaHome:(NSString *)customJavaHome
{
	[[NSUserDefaults standardUserDefaults] setObject:customJavaHome forKey:kJavaCustomHomePreferencesKey];
}

- (NSString *)customMavenHome
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:kMavenCustomHomePreferencesKey];
}

- (void)setCustomMavenHome:(NSString *)customMavenHome
{
	[[NSUserDefaults standardUserDefaults] setObject:customMavenHome forKey:kMavenCustomHomePreferencesKey];
}

@end
