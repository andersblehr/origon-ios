//
//  ScExternalDocument.h
//  ScolaApp
//
//  Created by Anders Blehr on 02.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScDocument;

@interface ScExternalDocument : ScCachedEntity

@property (nonatomic, retain) NSData * embeddedDocument;
@property (nonatomic, retain) ScDocument *document;

@end
