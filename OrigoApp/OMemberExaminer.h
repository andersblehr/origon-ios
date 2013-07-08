//
//  OMemberExaminer.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface OMemberExaminer : NSObject<UIActionSheetDelegate> {
@private
    OOrigo *_household;
    NSString *_memberGivenName;
    
    id<OMemberExaminerDelegate> _delegate;
}

@property (strong, nonatomic, readonly) NSString *motherId;
@property (strong, nonatomic, readonly) NSString *fatherId;

+ (OMemberExaminer *)examinerForHousehold:(OOrigo *)household;

- (void)examineMemberWithName:(NSString *)name isMinor:(BOOL)isMinor;

@end
