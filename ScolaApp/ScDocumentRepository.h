//
//  ScDocumentRepository.h
//  ScolaApp
//
//  Created by Anders Blehr on 15.10.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScDocument, ScScola;

@interface ScDocumentRepository : ScCachedEntity

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *documents;
@property (nonatomic, retain) ScScola *scola;
@end

@interface ScDocumentRepository (CoreDataGeneratedAccessors)

- (void)addDocumentsObject:(ScDocument *)value;
- (void)removeDocumentsObject:(ScDocument *)value;
- (void)addDocuments:(NSSet *)values;
- (void)removeDocuments:(NSSet *)values;

@end
