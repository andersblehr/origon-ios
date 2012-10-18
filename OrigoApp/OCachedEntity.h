//
//  OCachedEntity.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface OCachedEntity : NSManagedObject

@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSDate * dateExpires;
@property (nonatomic, retain) NSDate * dateModified;
@property (nonatomic, retain) NSString * entityId;
@property (nonatomic, retain) NSNumber * hashCode;
@property (nonatomic, retain) NSNumber * isShared;
@property (nonatomic, retain) NSString * origoId;

@end
