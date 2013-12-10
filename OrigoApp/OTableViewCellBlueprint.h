//
//  OTableViewCellBlueprint.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

extern CGFloat const kDefaultCellHeight;
extern CGFloat const kDefaultCellPadding;
extern CGFloat const kMinimumCellPadding;
extern CGFloat const kPhotoFrameWidth;

@interface OTableViewCellBlueprint : NSObject {
@private
    OState *_state;
    NSString *_stateAction;
    
    NSArray *_textViewKeys;
    NSArray *_detailKeys;
    NSArray *_allInputFieldKeys;
    
    NSMutableArray *_displayableInputFieldKeys;
}

@property (nonatomic, readonly) BOOL hasPhoto;
@property (nonatomic, readonly) BOOL fieldsAreLabeled;
@property (nonatomic, readonly) BOOL fieldsShouldDeemphasiseOnEndEdit;

@property (strong, nonatomic, readonly) NSString *titleKey;
@property (strong, nonatomic, readonly) NSArray *detailKeys;
@property (strong, nonatomic, readonly) NSArray *displayableInputFieldKeys;
@property (strong, nonatomic, readonly) NSArray *allInputFieldKeys;
@property (strong, nonatomic, readonly) NSArray *indirectKeys;

- (id)initWithState:(OState *)state;
- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

- (OInputField *)inputFieldWithKey:(NSString *)key delegate:(id)delegate;
- (CGFloat)cellHeightWithEntity:(OReplicatedEntity *)entity cell:(OTableViewCell *)cell;

@end
