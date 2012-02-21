//
//  ScCachedEntity.h
//  ScolaApp
//
//  Created by Anders Blehr on 21.02.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ScCachedEntity : NSManagedObject

@property (nonatomic, retain) NSNumber * _isCoreEntity;
@property (nonatomic, retain) NSNumber * _remotePersistenceState;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSDate * dateExpires;
@property (nonatomic, retain) NSDate * dateModified;

@end
