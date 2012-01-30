//
//  NSEntityDescription+ScRemotePersistenceHelper.h
//  ScolaApp
//
//  Created by Anders Blehr on 11.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSEntityDescription (ScRemotePersistenceHelper)

- (NSString *)route;
- (NSString *)lookupKey;
- (NSString *)expiresInTimeframe;

@end
