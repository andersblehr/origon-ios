//
//  ScToDoAssignment.h
//  ScolaApp
//
//  Created by Anders Blehr on 15.10.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScMember, ScToDoItem;

@interface ScToDoAssignment : ScCachedEntity

@property (nonatomic, retain) NSNumber * assigneeDidDecline;
@property (nonatomic, retain) NSNumber * isComplete;
@property (nonatomic, retain) ScMember *assignee;
@property (nonatomic, retain) ScToDoItem *toDoItem;

@end
