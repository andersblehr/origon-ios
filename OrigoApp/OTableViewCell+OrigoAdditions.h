//
//  OTableViewCell+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 27/10/14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OTableViewCell.h"

@interface OTableViewCell (OrigoAdditions)

- (void)loadMember:(id<OMember>)member inOrigo:(id<OOrigo>)origo includeRelations:(BOOL)includeRelations;
- (void)loadImageForMember:(id<OMember>)member;
- (void)loadImageForOrigo:(id<OOrigo>)origo;

- (void)loadTonedDownIconWithFileName:(NSString *)fileName;

@end
