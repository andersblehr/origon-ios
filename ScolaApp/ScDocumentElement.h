//
//  ScDocumentElement.h
//  ScolaApp
//
//  Created by Anders Blehr on 28.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ScDocument;

@interface ScDocumentElement : NSManagedObject

@property (nonatomic, retain) NSNumber * sequenceNumber;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) ScDocument *document;

@end
