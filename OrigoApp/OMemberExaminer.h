//
//  OMemberExaminer.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OMemberExaminer : NSObject<UIActionSheetDelegate> {
@private
    id<OMember> _member;
    id<OOrigo> _residence;
    id<OMember> _currentCandidate;
    
    NSInteger _parentCandidateStatus;
    NSArray *_candidates;
    NSMutableSet *_examinedCandidates;
    NSMutableArray *_registrantOffspring;
    
    id<OMemberExaminerDelegate> _delegate;
}

+ (instancetype)examinerForResidence:(id<OOrigo>)residence delegate:(id)delegate;

- (void)examineMember:(id)member;

@end
