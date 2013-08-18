//
//  Task.h
//  IceCube
//
//  Created by Marian Bouček on 18.08.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Task : NSManagedObject

@property (nonatomic, retain) NSString * directory;
@property (nonatomic, retain) NSString * command;
@property (nonatomic, retain) NSString * name;

+ (NSString *)entityName;

@end
