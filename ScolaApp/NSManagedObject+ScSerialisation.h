//
//  NSManagedObject+ScSerialisation.h
//  ScolaApp
//
//  Created by Anders Blehr on 11.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (ScSerialisation)

- (NSDictionary *)toDictionary;

@end
