//
//  ScToDoAssignment.h
//  ScolaApp
//
//  Created by Anders Blehr on 28.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ScScolaMember, ScToDoItem;

@interface ScToDoAssignment : NSManagedObject

@property (nonatomic, retain) NSNumber * declined;
@property (nonatomic, retain) NSNumber * done;
@property (nonatomic, retain) ScScolaMember *assignee;
@property (nonatomic, retain) ScToDoItem *toDoItem;

@end
