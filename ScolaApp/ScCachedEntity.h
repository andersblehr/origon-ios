//
//  ScCachedEntity.h
//  ScolaApp
//
//  Created by Anders Blehr on 25.02.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ScCachedEntity : NSManagedObject

@property (nonatomic, retain) NSNumber * isCoreEntityN;
@property (nonatomic, retain) NSNumber * remotePersistenceStateN;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSDate * dateExpires;
@property (nonatomic, retain) NSDate * dateModified;
@property (nonatomic, retain) NSString * entityId;

@end
