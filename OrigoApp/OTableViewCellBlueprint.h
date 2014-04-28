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

@interface OTableViewCellBlueprint : NSObject {
@private
    OState *_state;
    NSString *_stateAction;
    
    NSArray *_inputKeys;
    NSArray *_multiLineTextKeys;
    NSMutableArray *_displayableInputKeys;
}

@property (nonatomic, readonly) BOOL hasPhoto;
@property (nonatomic, readonly) BOOL fieldsAreLabeled;
@property (nonatomic, readonly) BOOL fieldsShouldDeemphasiseOnEndEdit;

@property (strong, nonatomic, readonly) NSString *titleKey;
@property (strong, nonatomic, readonly) NSArray *detailKeys;
@property (strong, nonatomic, readonly) NSArray *inputKeys;
@property (strong, nonatomic, readonly) NSArray *displayableInputKeys;

- (instancetype)initWithState:(OState *)state;
- (instancetype)initWithState:(OState *)state reuseIdentifier:(NSString *)reuseIdentifier;

- (OInputField *)inputFieldWithKey:(NSString *)key delegate:(id)delegate;
- (CGFloat)cellHeightWithEntity:(id)entity cell:(OTableViewCell *)cell;

@end
