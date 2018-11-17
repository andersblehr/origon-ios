//
//  OTableViewCell+OrigonAdditions.h
//  Origon
//
//  Created by Anders Blehr on 27/10/14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OTableViewCell.h"

@interface OTableViewCell (OrigonAdditions)

- (void)loadImageForOrigo:(id<OOrigo>)origo;
- (void)loadImageForMember:(id<OMember>)member;
- (void)loadImageForMembers:(NSArray *)members;
- (void)loadImageWithName:(NSString *)imageName tintColour:(UIColor *)tintColour;

- (void)loadMember:(id<OMember>)member inOrigo:(id<OOrigo>)origo;
- (void)loadMember:(id<OMember>)member inOrigo:(id<OOrigo>)origo excludeRoles:(BOOL)excludeRoles excludeRelations:(BOOL)excludeRelations;

@end
