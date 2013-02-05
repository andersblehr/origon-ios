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
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"


@implementation OMembership (OrigoExtensions)

#pragma mark - Convenience methods

- (BOOL)hasContactRole
{
    return (self.contactRole != nil);
}


#pragma mark - OReplicateEntity (OReplicateEntityExtentions) overrides

- (void)makeGhost
{
    [super makeGhost];
    
    self.contactRole = nil;
    self.contactType = nil;
    self.isActive = @NO;
    self.isAdmin = @NO;
}


#pragma mark - OReplicatedEntity+OrigoExtensions overrides

- (NSString *)listNameForState:(OState *)state
{
    NSString *listName = nil;
    
    if (state.actionIsList) {
        listName = [self.member listNameForState:state];
    } else if (state.actionIsDisplay && state.targetIsMember) {
        listName = [self.origo listNameForState:state];
    }
    
    return listName;
}


- (NSString *)listDetailsForState:(OState *)state
{
    NSString *listDetails = nil;
    
    if (state.actionIsList) {
        listDetails = [self.member listDetailsForState:state];
    }
    
    return listDetails;
}


- (UIImage *)listImageForState:(OState *)state
{
    UIImage *listImage = nil;
    
    if (state.actionIsList) {
        listImage = [self.member listImageForState:state];
    } else if (state.actionIsDisplay && state.targetIsMember) {
        listImage = [self.origo listImageForState:state];
    }
    
    return listImage;
}


#pragma mark - Comparison

- (NSComparisonResult)compare:(OMembership *)other
{
    NSComparisonResult comparisonResult = NSOrderedSame;

    if ([OState s].targetIsMember) {
        comparisonResult = [self.member.name localizedCaseInsensitiveCompare:other.member.name];
        
        if ([OState s].aspectIsResidence) {
            BOOL thisMemberIsMinor = [self.member isMinor];
            BOOL otherMemberIsMinor = [other.member isMinor];
            
            if ([self.origo isResidence] && (thisMemberIsMinor != otherMemberIsMinor)) {
                if (thisMemberIsMinor && !otherMemberIsMinor) {
                    comparisonResult = NSOrderedDescending;
                } else {
                    comparisonResult = NSOrderedAscending;
                }
            }
        }
    } else if ([OState s].targetIsOrigo) {
        comparisonResult = [self.origo.name localizedCaseInsensitiveCompare:other.origo.name];
    }

    return comparisonResult;
}

@end
