//
//  ODocumentElement.h
//  OrigoApp
//
//  Created by Anders Blehr on 29.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"

@class ODocument;

@interface ODocumentElement : OReplicatedEntity

@property (nonatomic, retain) NSNumber * sequenceNumber;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) ODocument *document;

@end
