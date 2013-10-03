//
//  MBMavenParserDelegate.h
//  IceCube
//
//  Created by Marian Bouček on 24.09.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

@protocol MBMavenParserDelegate <NSObject>

-(void)task:(NSString *)executable willStartWithArguments:(NSString *)arguments onPath:(NSString *)projectDirectory;

-(void)buildDidStartWithTaskList:(NSArray *)taskList;
-(void)buildDidEndSuccessfully:(BOOL) result;

-(void)projectDidStartWithName:(NSString *)name;
-(void)newLineDidRecieve:(NSString *)line;

@end
