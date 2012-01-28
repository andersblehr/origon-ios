//
//  ScHousehold.h
//  ScolaApp
//
//  Created by Anders Blehr on 28.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScEvent, ScParttimeHousehold, ScPerson;

@interface ScHousehold : ScCachedEntity

@property (nonatomic, retain) NSString * addressLine1;
@property (nonatomic, retain) NSString * addressLine2;
@property (nonatomic, retain) NSString * postCodeAndCity;
@property (nonatomic, retain) NSString * contry;
@property (nonatomic, retain) NSSet *events;
@property (nonatomic, retain) NSSet *members;
@property (nonatomic, retain) NSSet *parttimeMembers;
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
