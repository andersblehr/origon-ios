//
//  OTableViewCell+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 27/10/14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OTableViewCell.h"

@interface OTableViewCell (OrigoAdditions)

- (void)loadImageForOrigo:(id<OOrigo>)origo;
- (void)loadImageForMember:(id<OMember>)member;
- (void)loadImageForMembers:(NSArray *)members;

- (void)loadMember:(id<OMember>)member inOrigo:(id<OOrigo>)origo;
- (void)loadMember:(id<OMember>)member inOrigo:(id<OOrigo>)origo excludeRoles:(BOOL)excludeRoles excludeRelations:(BOOL)excludeRelations;

@end
