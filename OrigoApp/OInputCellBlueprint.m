//
//  OInputCellBlueprint.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OInputCellBlueprint.h"

CGFloat const kDefaultCellHeight = 45.f;
CGFloat const kDefaultCellPadding = 10.f;
CGFloat const kMinimumCellPadding = 0.1f;
CGFloat const kPhotoFrameWidth = 55.f;


@implementation OInputCellBlueprint

#pragma mark - Initialisation

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _hasPhoto = NO;
        _fieldsAreLabeled = YES;
        _fieldsShouldDeemphasiseOnEndEdit = YES;
        _isEditableListCellBlueprint = NO;
    }
    
    return self;
}


#pragma mark - Factory methods

+ (OInputCellBlueprint *)editableListCellBlueprint
{
    OInputCellBlueprint *blueprint = [[self alloc] init];
    blueprint.titleKey = kExternalKeyEditableListCellContent;
    blueprint.fieldsAreLabeled = NO;
    blueprint.isEditableListCellBlueprint = YES;
    
    return blueprint;
}


#pragma mark - Custom accessors

- (NSArray *)inputKeys
{
    if (!_inputKeys) {
        if (_titleKey) {
            _inputKeys = [@[_titleKey] arrayByAddingObjectsFromArray:_detailKeys];
        } else {
            _inputKeys = _detailKeys;
        }
    }
    
    return _inputKeys;
}

@end
