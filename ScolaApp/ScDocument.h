//
//  ScDocument.h
//  ScolaApp
//
//  Created by Anders Blehr on 10.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScDocumentElement, ScDocumentRepository, ScExternalDocument, ScScolaMember;

@interface ScDocument : ScCachedEntity

@property (nonatomic, strong) NSNumber * doesExpire;
@property (nonatomic, strong) NSNumber * isExternal;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) ScScolaMember *author;
@property (nonatomic, strong) NSSet *documentElements;
@property (nonatomic, strong) ScExternalDocument *externalDocument;
@property (nonatomic, strong) ScDocumentRepository *repository;
@end

@interface ScDocument (CoreDataGeneratedAccessors)

- (void)addDocumentElementsObject:(ScDocumentElement *)value;
- (void)removeDocumentElementsObject:(ScDocumentElement *)value;
- (void)addDocumentElements:(NSSet *)values;
- (void)removeDocumentElements:(NSSet *)values;

@end
