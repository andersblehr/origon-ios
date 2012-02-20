//
//  ScCachedEntity.h
//  ScolaApp
//
//  Created by Anders Blehr on 20.02.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ScCachedEntity : NSManagedObject

@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSDate * dateExpires;
@property (nonatomic, retain) NSDate * dateModified;
@property (nonatomic, retain) NSNumber * isCoreEntity;
@property (nonatomic, retain) NSNumber * isScheduledForRemotePersistence;

@end
