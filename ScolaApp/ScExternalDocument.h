//
//  ScExternalDocument.h
//  ScolaApp
//
//  Created by Anders Blehr on 05.02.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ScDocument;

@interface ScExternalDocument : NSManagedObject

@property (nonatomic, retain) NSData * embeddedDocument;
@property (nonatomic, retain) ScDocument *document;

@end
