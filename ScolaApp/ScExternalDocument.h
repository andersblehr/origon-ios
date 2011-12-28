//
//  ScExternalDocument.h
//  ScolaApp
//
//  Created by Anders Blehr on 10.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ScDocument;

@interface ScExternalDocument : NSManagedObject

@property (nonatomic, strong) NSData * embeddedDocument;
@property (nonatomic, strong) ScDocument *document;

@end
