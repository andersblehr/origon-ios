//
//  ScCachedAddress.h
//  ScolaApp
//
//  Created by Anders Blehr on 10.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ScHousehold, ScOrganisation;

@interface ScCachedAddress : NSManagedObject

@property (nonatomic, strong) NSString * addressLine1;
@property (nonatomic, strong) NSString * addressLine2;
@property (nonatomic, strong) NSString * addressLine3;
@property (nonatomic, strong) NSString * country;
@property (nonatomic, strong) NSString * landline;
@property (nonatomic, strong) NSSet *households;
@property (nonatomic, strong) NSSet *organisations;
@end

@interface ScCachedAddress (CoreDataGeneratedAccessors)

- (void)addHouseholdsObject:(ScHousehold *)value;
- (void)removeHouseholdsObject:(ScHousehold *)value;
- (void)addHouseholds:(NSSet *)values;
- (void)removeHouseholds:(NSSet *)values;

- (void)addOrganisationsObject:(ScOrganisation *)value;
- (void)removeOrganisationsObject:(ScOrganisation *)value;
- (void)addOrganisations:(NSSet *)values;
- (void)removeOrganisations:(NSSet *)values;

@end
