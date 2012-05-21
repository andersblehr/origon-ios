//
//  ScMemberResidency+ScMemberResidencyExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 22.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScMemberResidency+ScMemberResidencyExtensions.h"

#import "ScCachedEntity+ScCachedEntityExtensions.h"

#import "ScScola.h"


@implementation ScMemberResidency (ScMemberResidencyExtensions)


#pragma mark - ScCachedEntity (ScCachedEntityExtentions) overrides

- (BOOL)isPersistedProperty:(NSString *)property
{
    BOOL doPersist = [super isPersistedProperty:property];
    
    doPersist = doPersist && ![property isEqualToString:@"resident"];
    doPersist = doPersist && ![property isEqualToString:@"residence"];
    
    return doPersist;
}


- (void)internaliseRelationships
{
    [super internaliseRelationships];
    
    self.resident = self.member;
    self.residence = self.scola;
}

@end
