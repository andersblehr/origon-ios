//
//  ScCachedEntity.h
//  ScolaApp
//
//  Created by Anders Blehr on 14.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ScCachedEntity : NSManagedObject

@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSDate * dateExpires;
@property (nonatomic, retain) NSDate * dateModified;
@property (nonatomic, retain) NSString * entityId;
@property (nonatomic, retain) NSNumber * hashCode;
@property (nonatomic, retain) NSNumber * isShared;
@property (nonatomic, retain) NSString * scolaId;

@end
