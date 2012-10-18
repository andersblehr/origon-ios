//
//  OMemberResidency+OMemberResidencyExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMemberResidency+OMemberResidencyExtensions.h"

#import "NSManagedObjectContext+OManagedObjectContextExtensions.h"

#import "OMeta.h"

#import "OMember.h"
#import "OOrigo.h"

#import "OCachedEntity+OCachedEntityExtensions.h"


@implementation OMemberResidency (OMemberResidencyExtensions)


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
    self.residence = self.origo;
}

@end
