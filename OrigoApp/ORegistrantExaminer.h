//
//  ORegistrantExaminer.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORegistrantExaminer : NSObject<UIActionSheetDelegate> {
@private
    OOrigo *_residence;
    OMember *_currentCandidate;
    
    BOOL _isMinor;
    
    NSString *_givenName;
    NSDate *_dateOfBirth;
    NSInteger _parentCandidateStatus;
    NSArray *_candidates;
    NSMutableSet *_examinedCandidates;
    NSMutableArray *_registrantOffspring;
    
    id<ORegistrantExaminerDelegate> _delegate;
}

@property (strong, nonatomic, readonly) NSString *registrantId;
@property (strong, nonatomic, readonly) NSString *gender;
@property (strong, nonatomic, readonly) NSString *motherId;
@property (strong, nonatomic, readonly) NSString *fatherId;

- (id)initWithOrigo:(OOrigo *)origo;

- (void)examineRegistrant:(OMember *)registrant;
- (void)examineRegistrantWithName:(NSString *)name;
- (void)examineRegistrantWithName:(NSString *)name gender:(NSString *)gender;
- (void)examineRegistrantWithName:(NSString *)name dateOfBirth:(NSDate *)dateOfBirth;

@end
