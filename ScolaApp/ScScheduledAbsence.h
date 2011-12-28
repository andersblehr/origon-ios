//
//  ScScheduledAbsence.h
//  ScolaApp
//
//  Created by Anders Blehr on 10.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScPerson;

@interface ScScheduledAbsence : ScCachedEntity

@property (nonatomic, strong) NSDate * absenceEnd;
@property (nonatomic, strong) NSDate * absenceStart;
@property (nonatomic, strong) NSString * descriptionText;
@property (nonatomic, strong) ScPerson *person;

@end
