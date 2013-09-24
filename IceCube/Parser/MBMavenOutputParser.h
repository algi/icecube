//
//  MBMavenOutputParser.h
//  IceCube
//
//  Created by Marian Bouček on 31.03.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MBMavenParserDelegate;

@interface MBMavenOutputParser : NSObject

-(id)initWithDelegate:(id<MBMavenParserDelegate>)delegate;

-(void)parseLine:(NSString *)line;

@end
