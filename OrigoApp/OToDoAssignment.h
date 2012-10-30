//
//  OToDoAssignment.h
//  OrigoApp
//
//  Created by Anders Blehr on 29.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"

@class OMember, OToDoItem;

@interface OToDoAssignment : OReplicatedEntity

@property (nonatomic, retain) NSNumber * assigneeDidDecline;
@property (nonatomic, retain) NSNumber * isComplete;
@property (nonatomic, retain) OMember *assignee;
@property (nonatomic, retain) OToDoItem *toDoItem;

@end
