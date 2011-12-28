//
//  ScDocumentRepository.h
//  ScolaApp
//
//  Created by Anders Blehr on 10.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScDocument, ScScola;

@interface ScDocumentRepository : ScCachedEntity

@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSSet *documents;
@property (nonatomic, strong) ScScola *scola;
@end

@interface ScDocumentRepository (CoreDataGeneratedAccessors)

- (void)addDocumentsObject:(ScDocument *)value;
- (void)removeDocumentsObject:(ScDocument *)value;
- (void)addDocuments:(NSSet *)values;
- (void)removeDocuments:(NSSet *)values;

@end
