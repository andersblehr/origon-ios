//
//  OMemberExaminerDelegate.h
//  OrigoApp
//
//  Created by Anders Blehr on 08.07.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@protocol OMemberExaminerDelegate <NSObject>

@required
- (void)examinerDidFinishExamining;

@end
