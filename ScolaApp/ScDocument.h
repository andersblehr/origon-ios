//
//  ScDocument.h
//  ScolaApp
//
//  Created by Anders Blehr on 30.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScDocumentElement, ScDocumentRepository, ScExternalDocument, ScScolaMember;

@interface ScDocument : ScCachedEntity

@property (nonatomic, retain) NSNumber * doesExpire;
@property (nonatomic, retain) NSNumber * isExternal;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) ScScolaMember *author;
@property (nonatomic, retain) NSSet *documentElements;
@property (nonatomic, retain) ScExternalDocument *externalDocument;
@property (nonatomic, retain) ScDocumentRepository *repository;
@end

@interface ScDocument (CoreDataGeneratedAccessors)

- (void)addDocumentElementsObject:(ScDocumentElement *)value;
- (void)removeDocumentElementsObject:(ScDocumentElement *)value;
- (void)addDocumentElements:(NSSet *)values;
- (void)removeDocumentElements:(NSSet *)values;

@end
