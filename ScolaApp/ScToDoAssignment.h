//
//  ScToDoAssignment.h
//  ScolaApp
//
//  Created by Anders Blehr on 10.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ScScolaMember, ScToDoItem;

@interface ScToDoAssignment : NSManagedObject

@property (nonatomic, strong) NSNumber * declined;
@property (nonatomic, strong) NSNumber * done;
@property (nonatomic, strong) ScScolaMember *assignee;
@property (nonatomic, strong) ScToDoItem *toDoItem;

@end
