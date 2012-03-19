//
//  ScCachedEntity.h
//  ScolaApp
//
//  Created by Anders Blehr on 19.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ScCachedEntity : NSManagedObject

@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSDate * dateExpires;
@property (nonatomic, retain) NSDate * dateModified;
@property (nonatomic, retain) NSString * entityId;
@property (nonatomic, retain) NSNumber * remotePersistenceState;
@property (nonatomic, retain) NSString * scolaId;

@end
