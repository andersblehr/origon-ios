//
//  OEntityObserver.h
//  OrigoApp
//
//  Created by Anders Blehr on 28.11.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@protocol OEntityObserver <NSObject>

@required
- (void)entityDidChange;

@end
