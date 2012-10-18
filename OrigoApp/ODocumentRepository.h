//
//  ODocumentRepository.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OCachedEntity.h"

@class ODocument, OOrigo;

@interface ODocumentRepository : OCachedEntity

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *documents;
@property (nonatomic, retain) OOrigo *origo;
@end

@interface ODocumentRepository (CoreDataGeneratedAccessors)

- (void)addDocumentsObject:(ODocument *)value;
- (void)removeDocumentsObject:(ODocument *)value;
- (void)addDocuments:(NSSet *)values;
- (void)removeDocuments:(NSSet *)values;

@end
