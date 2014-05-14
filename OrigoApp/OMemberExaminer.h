//
//  OMemberExaminer.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OMemberExaminer : NSObject

+ (instancetype)examinerForResidence:(id<OOrigo>)residence delegate:(id)delegate;

- (void)examineMember:(id)member;

@end
