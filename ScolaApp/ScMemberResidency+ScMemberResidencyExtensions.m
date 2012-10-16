//
//  ScMemberResidency+ScMemberResidencyExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 22.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScMemberResidency+ScMemberResidencyExtensions.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"

#import "ScMeta.h"

#import "ScMember.h"
#import "ScScola.h"

#import "ScCachedEntity+ScCachedEntityExtensions.h"


@implementation ScMemberResidency (ScMemberResidencyExtensions)


#pragma mark - ScCachedEntity (ScCachedEntityExtentions) overrides

- (BOOL)isTransientProperty:(NSString *)property
{
    BOOL isTransient = [super isTransientProperty:property];
    
    isTransient = isTransient || [property isEqualToString:@"resident"];
    isTransient = isTransient || [property isEqualToString:@"residence"];
    
    return isTransient;
}


- (void)internaliseRelationships
{
    [super internaliseRelationships];
    
    self.resident = self.member;
    self.residence = self.scola;
}

@end
