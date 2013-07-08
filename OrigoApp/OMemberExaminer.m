//
//  OMemberExaminer.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMemberExaminer.h"


@implementation OMemberExaminer

#pragma mark - Auxiliary methods

- (NSArray *)parentCandidates
{
    return nil;
}


#pragma mark - Examination loops

- (void)examineMinor
{
    
}


- (void)examineMember
{
    
}


#pragma mark - Initialisation

- (id)initWithHousehold:(OOrigo *)household;
{
    self = [super init];
    
    if (self) {
        _household = household;
        _delegate = (id<OMemberExaminerDelegate>)[OState s].viewController;
    }
    
    return self;
}


#pragma mark - Factory methods

+ (OMemberExaminer *)examinerForHousehold:(OOrigo *)household
{
    return [[OMemberExaminer alloc] initWithHousehold:household];
}


#pragma mark - Examining new members

- (void)examineMemberWithName:(NSString *)name isMinor:(BOOL)isMinor
{
    _memberGivenName = [OUtil givenNameFromFullName:name];
    
    if (isMinor) {
        [self examineMinor];
    } else {
        [self examineMember];
    }
}

@end
