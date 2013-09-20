//
//  MBMavenOutputParser.h
//  IceCube
//
//  Created by Marian Bouček on 31.03.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MBMavenServiceCallback;

@interface MBMavenOutputParser : NSObject

-(id)initWithDelegate:(id<MBMavenServiceCallback>)delegate;

-(void)parseLine:(NSString *)line;

@end
