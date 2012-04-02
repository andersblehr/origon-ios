//
//  ScDocumentRepository.h
//  ScolaApp
//
//  Created by Anders Blehr on 02.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScDocument;

@interface ScDocumentRepository : ScCachedEntity

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *documents;
@end

@interface ScDocumentRepository (CoreDataGeneratedAccessors)

- (void)addDocumentsObject:(ScDocument *)value;
- (void)removeDocumentsObject:(ScDocument *)value;
- (void)addDocuments:(NSSet *)values;
- (void)removeDocuments:(NSSet *)values;

@end
