//
//  ScScheduledAbsence.h
//  ScolaApp
//
//  Created by Anders Blehr on 06.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScMember;

@interface ScScheduledAbsence : ScCachedEntity

@property (nonatomic, retain) NSDate * absenceEnd;
@property (nonatomic, retain) NSDate * absenceStart;
@property (nonatomic, retain) NSString * descriptionText;
@property (nonatomic, retain) ScMember *person;

@end
