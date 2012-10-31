//
//  OReplicatedEntity.h
//  OrigoApp
//
//  Created by Anders Blehr on 31.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface OReplicatedEntity : NSManagedObject

@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSDate * dateExpires;
@property (nonatomic, retain) NSDate * dateReplicated;
@property (nonatomic, retain) NSString * entityId;
@property (nonatomic, retain) NSNumber * hashCode;
@property (nonatomic, retain) NSString * origoId;

@end
