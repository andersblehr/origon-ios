//
//  OMembership+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMembership.h"

@interface OMembership (OrigoExtensions)

- (BOOL)hasContactRole;

- (BOOL)isFull;
- (BOOL)isParticipancy;
- (BOOL)isResidency;
- (BOOL)isAssociate;

- (void)promoteToFull;
- (void)demoteToAssociate;
- (void)alignWithOrigoIsAssociate:(BOOL)isAssociate;

@end
