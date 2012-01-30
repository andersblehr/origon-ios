//
//  ScOrganisation.h
//  ScolaApp
//
//  Created by Anders Blehr on 30.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScEvent, ScOrganisationContact, ScScola;

@interface ScOrganisation : ScCachedEntity

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * addressLine1;
@property (nonatomic, retain) NSString * addressLine2;
@property (nonatomic, retain) NSString * postCodeAndCity;
@property (nonatomic, retain) NSString * phoneNumber;
@property (nonatomic, retain) NSSet *contacts;
@property (nonatomic, retain) NSSet *events;
@property (nonatomic, retain) NSSet *scolas;
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
