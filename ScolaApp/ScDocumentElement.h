//
//  ScDocumentElement.h
//  ScolaApp
//
//  Created by Anders Blehr on 02.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScDocument;

@interface ScDocumentElement : ScCachedEntity

@property (nonatomic, retain) NSNumber * sequenceNumber;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) ScDocument *document;

@end
