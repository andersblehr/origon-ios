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

- (BOOL)doPersistProperty:(NSString *)property
{
    BOOL isIgnored = NO;
    
    isIgnored = isIgnored || [property isEqualToString:@"resident"];
    isIgnored = isIgnored || [property isEqualToString:@"residence"];
    
    return !isIgnored;
}


- (void)internaliseRelationships
{
    [super internaliseRelationships];
    
    self.resident = self.member;
    self.residence = self.scola;
}

@end
