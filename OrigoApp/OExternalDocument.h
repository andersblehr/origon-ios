//
//  OExternalDocument.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OCachedEntity.h"

@class ODocument;

@interface OExternalDocument : OCachedEntity

@property (nonatomic, retain) NSData * embeddedDocument;
@property (nonatomic, retain) ODocument *document;

@end
