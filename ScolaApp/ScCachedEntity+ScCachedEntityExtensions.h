//
//  ScCachedEntity+ScCachedEntityExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 20.02.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScCachedEntity.h"

@interface ScCachedEntity (ScCachedEntityExtensions)

- (NSString *)route;
- (NSString *)lookupKey;
- (NSString *)expiresInTimeframe;

- (NSDictionary *)toDictionaryForRemotePersistence;

@end
