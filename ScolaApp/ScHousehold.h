//
//  ScHousehold.h
//  ScolaApp
//
//  Created by Anders Blehr on 10.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScCachedAddress, ScEvent, ScParttimeHousehold, ScPerson;

@interface ScHousehold : ScCachedEntity

@property (nonatomic, strong) ScCachedAddress *address;
@property (nonatomic, strong) NSSet *events;
@property (nonatomic, strong) NSSet *members;
@property (nonatomic, strong) NSSet *parttimeMembers;
@end

@interface ScHousehold (CoreDataGeneratedAccessors)

- (void)addEventsObject:(ScEvent *)value;
- (void)removeEventsObject:(ScEvent *)value;
- (void)addEvents:(NSSet *)values;
- (void)removeEvents:(NSSet *)values;

- (void)addMembersObject:(ScPerson *)value;
- (void)removeMembersObject:(ScPerson *)value;
- (void)addMembers:(NSSet *)values;
- (void)removeMembers:(NSSet *)values;

- (void)addParttimeMembersObject:(ScParttimeHousehold *)value;
- (void)removeParttimeMembersObject:(ScParttimeHousehold *)value;
- (void)addParttimeMembers:(NSSet *)values;
- (void)removeParttimeMembers:(NSSet *)values;

@end
