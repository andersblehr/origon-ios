//
//  ScOrganisation.h
//  ScolaApp
//
//  Created by Anders Blehr on 10.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScCachedAddress, ScEvent, ScOrganisationContact, ScScola;

@interface ScOrganisation : ScCachedEntity

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) ScCachedAddress *address;
@property (nonatomic, strong) NSSet *contacts;
@property (nonatomic, strong) NSSet *events;
@property (nonatomic, strong) NSSet *scolas;
@end

@interface ScOrganisation (CoreDataGeneratedAccessors)

- (void)addContactsObject:(ScOrganisationContact *)value;
- (void)removeContactsObject:(ScOrganisationContact *)value;
- (void)addContacts:(NSSet *)values;
- (void)removeContacts:(NSSet *)values;

- (void)addEventsObject:(ScEvent *)value;
- (void)removeEventsObject:(ScEvent *)value;
- (void)addEvents:(NSSet *)values;
- (void)removeEvents:(NSSet *)values;

- (void)addScolasObject:(ScScola *)value;
- (void)removeScolasObject:(ScScola *)value;
- (void)addScolas:(NSSet *)values;
- (void)removeScolas:(NSSet *)values;

@end
