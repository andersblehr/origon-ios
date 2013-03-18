//
//  OReplicatedEntity.h
//  OrigoApp
//
//  Created by Anders Blehr on 13.03.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface OReplicatedEntity : NSManagedObject

@property (nonatomic, retain) NSString * createdBy;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSDate * dateExpires;
@property (nonatomic, retain) NSDate * dateReplicated;
@property (nonatomic, retain) NSString * entityId;
@property (nonatomic, retain) NSString * hashCode;
@property (nonatomic, retain) NSNumber * isExpired;
@property (nonatomic, retain) NSString * origoId;

@end
