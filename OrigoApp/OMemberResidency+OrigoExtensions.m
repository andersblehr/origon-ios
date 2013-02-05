//
//  OMemberResidency+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMemberResidency+OrigoExtensions.h"

#import "NSManagedObjectContext+OrigoExtensions.h"
#import "NSString+OrigoExtensions.h"

#import "OMeta.h"
#import "OState.h"

#import "OMember.h"
#import "OOrigo.h"
#import "OReplicatedEntity+OrigoExtensions.h"


@implementation OMemberResidency (OrigoExtensions)


#pragma mark - OReplicateEntity (OReplicateEntityExtentions) overrides

- (void)internaliseRelationships
{
    [super internaliseRelationships];
    
    self.resident = self.member;
    self.residence = self.origo;
}


- (void)makeGhost
{
    [super makeGhost];
    
    self.presentOn01Jan = @YES;
    self.daysAtATime = 0;
    self.switchDay = 0;
    self.switchFrequency = 0;
}


- (BOOL)propertyIsTransient:(NSString *)property
{
    BOOL isTransient = [super propertyIsTransient:property];
    
    isTransient = isTransient || [property isEqualToString:@"resident"];
    isTransient = isTransient || [property isEqualToString:@"residence"];
    
    return isTransient;
}


- (NSString *)listNameForState:(OState *)state
{
    NSString *listName = nil;
    
    if (state.actionIsList && state.targetIsOrigo) {
        listName = [self.origo listNameForState:state];
    } else {
        listName = [super listNameForState:state];
    }
    
    return listName;
}


- (NSString *)listDetailsForState:(OState *)state
{
    NSString *listDetails = nil;
    
    if (state.actionIsList && state.targetIsOrigo) {
        listDetails = [self.origo listDetailsForState:state];
    } else {
        listDetails = [super listDetailsForState:state];
    }
    
    return listDetails;
}


- (UIImage *)listImageForState:(OState *)state
{
    UIImage *listImage = nil;
    
    if (state.actionIsList && state.targetIsOrigo) {
        listImage = [self.origo listImageForState:state];
    } else {
        listImage = [super listImageForState:state];
    }
    
    return listImage;
}

@end
