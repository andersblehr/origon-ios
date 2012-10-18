//
//  OToDoAssignment.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OCachedEntity.h"

@class OMember, OToDoItem;

@interface OToDoAssignment : OCachedEntity

@property (nonatomic, retain) NSNumber * assigneeDidDecline;
@property (nonatomic, retain) NSNumber * isComplete;
@property (nonatomic, retain) OMember *assignee;
@property (nonatomic, retain) OToDoItem *toDoItem;

@end
