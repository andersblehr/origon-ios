//
//  OReplicatedEntity.h
//  Origon
//
//  Created by Anders Blehr on 11.10.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface OReplicatedEntity : NSManagedObject

@property (nonatomic, retain) NSString * createdBy;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSDate * dateReplicated;
@property (nonatomic, retain) NSString * entityId;
@property (nonatomic, retain) NSString * hashCode;
@property (nonatomic, retain) NSNumber * isExpired;
@property (nonatomic, retain) NSString * origoId;
@property (nonatomic, retain) NSString * modifiedBy;

@end
