//
//  ScScheduledAbsence.h
//  ScolaApp
//
//  Created by Anders Blehr on 02.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScScolaMember;

@interface ScScheduledAbsence : ScCachedEntity

@property (nonatomic, retain) NSDate * absenceEnd;
@property (nonatomic, retain) NSDate * absenceStart;
@property (nonatomic, retain) NSString * descriptionText;
@property (nonatomic, retain) ScScolaMember *person;

@end
