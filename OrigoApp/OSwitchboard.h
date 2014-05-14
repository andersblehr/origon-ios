//
//  OSwitchboard.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSwitchboard : NSObject

@property (nonatomic, readonly) CTCarrier *carrier;

- (NSArray *)toolbarButtonsForOrigo:(id<OOrigo>)origo;
- (NSArray *)toolbarButtonsForMember:(id<OMember>)member;

@end
