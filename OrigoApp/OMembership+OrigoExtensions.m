//
//  OMembership+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMembership+OrigoExtensions.h"

#import "OMeta.h"
#import "OState.h"

#import "OMember+OrigoExtensions.h"
#import "OMemberResidency.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"


@implementation OMembership (OrigoExtensions)

#pragma mark - Convenience methods

- (BOOL)hasContactRole
{
    return (self.contactRole != nil);
}


#pragma mark - OReplicatedEntity+OrigoExtensions overrides

- (void)makeGhost
{
    [super makeGhost];
    
    self.contactRole = nil;
    self.contactType = nil;
    self.isActive = @NO;
    self.isAdmin = @NO;
}


- (void)internaliseRelationships
{
    [super internaliseRelationships];

    if (self.associateMember) {
        self.associateOrigo = self.origo;
        self.origo = nil;
    }
}


- (NSString *)listNameForState:(OState *)state
{
    NSString *listName = nil;
    
    if (state.viewIsMemberList || state.viewIsOrigoList) {
        listName = [self.member listNameForState:state];
    } else if (state.viewIsMemberDetail) {
        listName = [self.origo listNameForState:state];
    }
    
    return listName;
}


- (NSString *)listDetailsForState:(OState *)state
{
    NSString *listDetails = nil;
    
    if (state.viewIsMemberList || state.viewIsOrigoList) {
        listDetails = [self.member listDetailsForState:state];
    }
    
    return listDetails;
}


- (UIImage *)listImageForState:(OState *)state
{
    UIImage *listImage = nil;
    
    if (state.viewIsMemberList || state.viewIsOrigoList) {
        listImage = [self.member listImageForState:state];
    } else if (state.viewIsMemberDetail) {
        listImage = [self.origo listImageForState:state];
    }
    
    return listImage;
}


#pragma mark - Comparison

- (NSComparisonResult)compare:(OMembership *)other
{
    NSComparisonResult result = NSOrderedSame;

    if ([OState s].viewIsMemberList) {
        result = [self.member compare:other.member];
    } else if ([OState s].viewIsOrigoList || [OState s].viewIsMemberDetail) {
        result = [self.origo compare:other.origo];
    }

    return result;
}

@end
