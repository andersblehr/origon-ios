//
//  NSManagedObjectContext+OrigonAdditions.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "NSManagedObjectContext+OrigonAdditions.h"


@implementation NSManagedObjectContext (OrigonAdditions)

#pragma mark - Auxiliary methods

- (id)entityOfClass:(Class)class withValue:(NSString *)value forKey:(NSString *)key
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass(class)];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K = %@", key, value]];
    
    id entity = nil;
    NSError *error = nil;
    NSArray *resultsArray = [self executeFetchRequest:request error:&error];
    
    if (resultsArray == nil) {
        OLogError(@"Error fetching entity on device: %@", [error localizedDescription]);
    } else if (resultsArray.count > 1) {
        OLogBreakage(@"Found more than one entity with '%@'='%@'.", key, value);
    } else if (resultsArray.count == 1) {
        entity = resultsArray[0];
    }
    
    return entity;
}


- (void)insertCommunityMembershipsContingentOnMembership:(OMembership *)membership
{
    if (![membership.member isJuvenile]) {
        OMember *member = membership.member;
        OOrigo *origo = membership.origo;
        
        if ([membership isResidency]) {
            NSMutableSet *candidateCommunities = [NSMutableSet set];
            NSMutableSet *communities = [NSMutableSet set];
            
            for (OMember *elder in [origo elders]) {
                for (OMembership *participancy in [elder participancies]) {
                    if ([participancy.origo isCommunity]) {
                        [candidateCommunities addObject:participancy.origo];
                    }
                }
            }
            
            for (OOrigo *candidateCommunity in candidateCommunities) {
                BOOL eldersAreMembers = YES;
                
                for (OMember *elder in [origo elders]) {
                    if (elder != member) {
                        eldersAreMembers = eldersAreMembers && [candidateCommunity hasMember:elder];
                    }
                }
                
                if (eldersAreMembers) {
                    [communities addObject:candidateCommunity];
                }
            }
            
            for (OOrigo *community in communities) {
                [community addMember:member];
            }
        } else if ([membership.origo isCommunity] && [membership isParticipancy]) {
            NSMutableArray *primaryCoHabitants = [[[member primaryResidence] elders] mutableCopy];
            [primaryCoHabitants removeObject:member];
            
            BOOL coHabitantIsMember = NO;
            
            for (OMember *coHabitant in primaryCoHabitants) {
                coHabitantIsMember = coHabitantIsMember || [origo hasMember:coHabitant];
            }
            
            if (!coHabitantIsMember) {
                for (OMember *coHabitant in primaryCoHabitants) {
                    [origo addMember:coHabitant];
                }
            }
        }
    }
}


- (void)expireCommunityMembershipsContingentOnMembership:(OMembership *)membership
{
    if (![membership.member isJuvenile]) {
        OMember *member = membership.member;
        OOrigo *origo = membership.origo;
        
        if ([membership isResidency]) {
            NSMutableArray *communities = [NSMutableArray array];
            
            for (OMembership *participancy in [member participancies]) {
                if ([participancy.origo isCommunity]) {
                    [communities addObject:participancy.origo];
                }
            }
            
            for (OOrigo *community in communities) {
                BOOL isCommunityResidence = YES;
                
                for (OMember *elder in [origo elders]) {
                    isCommunityResidence = isCommunityResidence && [community hasMember:elder];
                }
                
                if (isCommunityResidence) {
                    [[community membershipForMember:member] expire];
                }
            }
        } else if ([membership.origo isCommunity] && [membership isParticipancy]) {
            NSMutableArray *primaryCoHabitants = [[[member primaryResidence] elders] mutableCopy];
            [primaryCoHabitants removeObject:member];
            
            BOOL coHabitantsAreMembers = YES;
            
            for (OMember *coHabitant in primaryCoHabitants) {
                coHabitantsAreMembers = coHabitantsAreMembers && [origo hasMember:coHabitant];
            }
            
            if (coHabitantsAreMembers) {
                for (OMember *coHabitant in primaryCoHabitants) {
                    [[origo membershipForMember:coHabitant] expire];
                }
            }
        }
    }
}


#pragma mark - Entity cross-reference handling

- (NSString *)entityRefIdForEntity:(OReplicatedEntity *)entity inOrigoWithId:(NSString *)origoId
{
    return [entity.entityId stringByAppendingString:origoId separator:kSeparatorHash];
}


- (id)createEntityRefForEntity:(OReplicatedEntity *)entity inOrigo:(OOrigo *)origo
{
    NSString *entityRefId = [self entityRefIdForEntity:entity inOrigoWithId:origo.entityId];
    OReplicatedEntityRef *entityRef = [self entityWithId:entityRefId];
    
    if (!entityRef) {
        entityRef = [self insertEntityOfClass:[OReplicatedEntityRef class] inOrigo:origo entityId:entityRefId];
        entityRef.referencedEntityId = entity.entityId;
        entityRef.referencedEntityOrigoId = entity.origoId;
    } else if ([entityRef hasExpired]) {
        [entityRef unexpire];
    }
    
    return entityRef;
}


- (id)expireEntityRefForEntity:(OReplicatedEntity *)entity inOrigo:(OOrigo *)origo
{
    OReplicatedEntityRef *entityRef = [self createEntityRefForEntity:entity inOrigo:origo];
    entityRef.isExpired = @YES;
    
    return entityRef;
}


#pragma mark - Entity cross-referencing

- (NSSet *)entityRefsForPendingEntity:(OReplicatedEntity *)entity
{
    NSArray *pendingEntityRefs = nil;
    
    if ([entity isReplicated]) {
        NSError *error = nil;
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([OReplicatedEntityRef class])];
        [request setPredicate:[NSPredicate predicateWithFormat:@"entityId like[c] %@", [entity.entityId stringByAppendingString:@"#*"]]];
        
        pendingEntityRefs = [self executeFetchRequest:request error:&error];
        
        if (pendingEntityRefs == nil) {
            OLogError(@"Error fetching entity refs: %@", [error localizedDescription]);
        }
    }
    
    return pendingEntityRefs ? [NSSet setWithArray:pendingEntityRefs] : [NSSet set];
}


#pragma mark - Inserting entities

- (id)insertEntityOfClass:(Class)class entityId:(NSString *)entityId
{
    OReplicatedEntity *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(class) inManagedObjectContext:self];
    entity.entityId = entityId;
    entity.dateCreated = [NSDate date];
    entity.createdBy = [OMeta m].userEmail;

    return entity;
}


- (id)insertEntityOfClass:(Class)class inOrigo:(OOrigo *)origo entityId:(NSString *)entityId
{
    OReplicatedEntity *entity = [self insertEntityOfClass:class entityId:entityId];
    entity.origoId = origo.entityId;
    
    if ([entity.entity relationshipsByName][kRelationshipKeyOrigo]) {
        [entity setValue:origo forKey:kRelationshipKeyOrigo];
    }
    
    return entity;
}


- (id)insertEntityOfClass:(Class)class inOrigo:(OOrigo *)origo
{
    return [self insertEntityOfClass:class inOrigo:origo entityId:[OCrypto generateUUID]];
}


#pragma mark - Fetching entities

- (id)entityWithId:(NSString *)entityId
{
    return [self entityOfClass:[OReplicatedEntity class] withValue:entityId forKey:kPropertyKeyEntityId];
}


- (id<OMember>)memberWithEmail:(NSString *)email
{
    return [self entityOfClass:[OMember class] withValue:email forKey:kPropertyKeyEmail];
}


#pragma mark - Inserting & expiring entity cross references

- (void)insertCrossReferencesForMembership:(OMembership *)membership
{
    if (![membership.origo isStash]) {
        OMember *member = membership.member;
        OOrigo *origo = membership.origo;
        
        [self createEntityRefForEntity:member inOrigo:origo];
        
        for (OMembership *residency in [member residencies]) {
            if (residency != membership) {
                [self createEntityRefForEntity:residency inOrigo:origo];
                [self createEntityRefForEntity:residency.origo inOrigo:origo];
            }
        }
        
        if ([membership isMirrored]) {
            [self insertAdditionalCrossReferencesForMirroredMembership:membership];
        }
    }
}


- (void)insertAdditionalCrossReferencesForMirroredMembership:(OMembership *)membership
{
    OMember *member = membership.member;
    OOrigo *origo = membership.origo;
    
    if ([membership isResidency]) {
        NSMutableSet *mirroringOrigos = [NSMutableSet setWithArray:[member mirroringOrigos]];
        
        for (OMember *housemate in [member housemates]) {
            [mirroringOrigos addObjectsFromArray:[housemate mirroringOrigos]];
        }
        
        for (OOrigo *mirroringOrigo in mirroringOrigos) {
            if (mirroringOrigo != origo) {
                [self createEntityRefForEntity:membership inOrigo:mirroringOrigo];
                [self createEntityRefForEntity:origo inOrigo:mirroringOrigo];
            }
        }
        
        for (OOrigo *residence in [member residences]) {
            if (residence != origo) {
                [self createEntityRefForEntity:membership inOrigo:residence];
                [self createEntityRefForEntity:origo inOrigo:residence];
            }
        }
        
    }
    
    for (OMember *housemate in [member allHousemates]) {
        [origo addAssociateMember:housemate];
        
        for (OOrigo *mirroringOrigo in [member mirroringOrigos]) {
            if (mirroringOrigo != origo) {
                [mirroringOrigo addAssociateMember:housemate];
            }
        }
        
        if ([membership isResidency]) {
            for (OOrigo *residence in [housemate residences]) {
                if (residence != origo) {
                    [residence addAssociateMember:member];
                }
            }
            
            for (OOrigo *mirroringOrigo in [housemate mirroringOrigos]) {
                [mirroringOrigo addAssociateMember:member];
            }
        }
    }
    
    [self insertCommunityMembershipsContingentOnMembership:membership];
}


- (void)expireCrossReferencesForMembership:(OMembership *)membership
{
    if (![membership.origo isStash]) {
        OMember *member = membership.member;
        OOrigo *origo = membership.origo;
        
        [self expireEntityRefForEntity:member inOrigo:origo];
        
        for (OMembership *residency in [member residencies]) {
            if (residency != membership) {
                [self expireEntityRefForEntity:residency inOrigo:origo];
                
                if (![residency.origo hasMembersInCommonWithOrigo:origo]) {
                    [self expireEntityRefForEntity:residency.origo inOrigo:origo];
                }
            }
        }
        
        if ([membership isMirrored]) {
            [self expireAdditionalCrossReferencesForMirroredMembership:membership];
        }
    }
}


- (void)expireAdditionalCrossReferencesForMirroredMembership:(OMembership *)membership
{
    OMember *member = membership.member;
    OOrigo *origo = membership.origo;
    
    NSMutableSet *housemates = [NSMutableSet setWithArray:[member allHousemates]];
    
    if ([membership isResidency]) {
        if ([membership hasExpired]) {
            [housemates addObjectsFromArray:[origo residents]];
        }
        
        for (OOrigo *residence in [member residences]) {
            if (residence != origo) {
                [self expireEntityRefForEntity:membership inOrigo:residence];
                
                if (![origo hasMembersInCommonWithOrigo:residence]) {
                    [self expireEntityRefForEntity:origo inOrigo:residence];
                }
            }
        }
    }
    
    for (OMember *housemate in housemates) {
        if (![origo knowsAboutMember:housemate]) {
            [[origo associateMembershipForMember:housemate] expire];
        }
        
        for (OOrigo *mirroringOrigo in [member mirroringOrigos]) {
            if (mirroringOrigo != origo && ![mirroringOrigo knowsAboutMember:housemate]) {
                [[mirroringOrigo associateMembershipForMember:housemate] expire];
            }
        }
        
        if ([membership isResidency]) {
            for (OOrigo *residence in [housemate residences]) {
                if (residence != origo && ![residence knowsAboutMember:member]) {
                    [[residence associateMembershipForMember:member] expire];
                }
            }
            
            for (OOrigo *mirroringOrigo in [housemate mirroringOrigos]) {
                if (![mirroringOrigo knowsAboutMember:member]) {
                    [[mirroringOrigo associateMembershipForMember:member] expire];
                }
            }
        }
    }
    
    [self expireCommunityMembershipsContingentOnMembership:membership];
}


#pragma mark - Saving to device

- (void)save
{
    NSError *error;
    
    if ([self save:&error]) {
        OLogDebug(@"Entities successfully saved to device.");
    } else {
        [OAlert showAlertWithTitle:NSLocalizedString(@"Data error", @"") message:[NSString stringWithFormat:NSLocalizedString(@"An unrecoverable data error has occurred. To ensure the continued integrity of your data, you must delete and reinstall %@ on this device.", @""), [OMeta m].appName]];
        
        OLogError(@"Error saving to device: %@ [%@]", [error localizedDescription], [error userInfo]);
    }
}


- (void)saveEntityDictionaries:(NSArray *)entityDictionaries
{
    NSMutableSet *entities = [NSMutableSet set];
    
    for (NSDictionary *entityDictionary in entityDictionaries) {
        BOOL hasExpired = [entityDictionary[kPropertyKeyIsExpired] boolValue];
        NSString *entityId = entityDictionary[kPropertyKeyEntityId];
        
        if (!hasExpired || [self entityWithId:entityId]) {
            [entities addObject:[OReplicatedEntity instanceFromDictionary:entityDictionary]];
        }
    }
    
    NSMutableArray *expiredEntities = [NSMutableArray array];
    
    for (OReplicatedEntity *entity in entities) {
        [entity internaliseRelationships];
        
        if ([entity hasExpired]) {
            [expiredEntities addObject:entity];
        }
    }
    
    for (OReplicatedEntity *expiredEntity in expiredEntities) {
        [expiredEntity expire];
    }
    
    NSMutableArray *deletedEntities = [NSMutableArray array];
    NSUInteger numberOfDeletedEntities = -1;
    
    while (numberOfDeletedEntities != deletedEntities.count) {
        numberOfDeletedEntities = deletedEntities.count;
        
        for (OReplicatedEntity *entity in entities) {
            if (![deletedEntities containsObject:entity] && ![entity isSane]) {
                [self deleteObject:entity];
                [deletedEntities addObject:entity];
            }
        }
    }
    
    [self save];
    
    if ([[ODevice device] hasExpired]) {
        [[OMeta m] logout];
    }
}


#pragma mark - Entities to replicate

- (NSSet *)dirtyEntities
{
    NSMutableSet *dirtyEntities = [NSMutableSet set];
    NSMutableSet *unsavedEntities = [NSMutableSet set];
    
    [unsavedEntities unionSet:[self insertedObjects]];
    [unsavedEntities unionSet:[self updatedObjects]];
    
    for (OReplicatedEntity *entity in unsavedEntities) {
        if ([entity isDirty]) {
            [dirtyEntities addObject:entity];
            [dirtyEntities unionSet:[self entityRefsForPendingEntity:entity]];
        }
    }
    
    return dirtyEntities;
}

@end
