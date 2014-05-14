//
//  OTableViewCellBlueprint.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

extern CGFloat const kDefaultCellHeight;
extern CGFloat const kDefaultCellPadding;
extern CGFloat const kMinimumCellPadding;
extern CGFloat const kPhotoFrameWidth;

@interface OTableViewCellBlueprint : NSObject

@property (nonatomic, assign, readonly) BOOL hasPhoto;
@property (nonatomic, assign, readonly) BOOL fieldsAreLabeled;
@property (nonatomic, assign, readonly) BOOL fieldsShouldDeemphasiseOnEndEdit;

@property (nonatomic, readonly) NSString *titleKey;
@property (nonatomic, readonly) NSArray *detailKeys;
@property (nonatomic, readonly) NSArray *inputKeys;
@property (nonatomic, readonly) NSArray *multiLineTextKeys;

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;

- (OInputField *)inputFieldWithKey:(NSString *)key delegate:(id)delegate;

@end
