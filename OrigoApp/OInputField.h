//
//  OInputValueState.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@protocol OInputField <NSObject>

@required
- (BOOL)isDateField;
- (BOOL)hasValue;
- (BOOL)hasValidValue;

- (id)objectValue;
- (NSString *)textValue;

@end
