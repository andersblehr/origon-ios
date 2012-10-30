//
//  ODocument.h
//  OrigoApp
//
//  Created by Anders Blehr on 29.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"

@class ODocumentElement, ODocumentRepository, OExternalDocument, OMember;

@interface ODocument : OReplicatedEntity

@property (nonatomic, retain) NSNumber * doesExpire;
@property (nonatomic, retain) NSNumber * isExternal;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) OMember *author;
@property (nonatomic, retain) NSSet *documentElements;
@property (nonatomic, retain) OExternalDocument *externalDocument;
@property (nonatomic, retain) ODocumentRepository *repository;
@end

@interface ODocument (CoreDataGeneratedAccessors)

- (void)addDocumentElementsObject:(ODocumentElement *)value;
- (void)removeDocumentElementsObject:(ODocumentElement *)value;
- (void)addDocumentElements:(NSSet *)values;
- (void)removeDocumentElements:(NSSet *)values;

@end
