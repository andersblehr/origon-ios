//
//  OVisualConstraints.m
//  OrigoApp
//
//  Created by Anders Blehr on 18.11.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OVisualConstraints.h"

#import "NSDate+ODateExtensions.h"
#import "UIFont+OFontExtensions.h"

#import "OLogging.h"
#import "OState.h"
#import "OTableViewCell.h"
#import "OTextField.h"
#import "OTextView.h"

#import "OReplicatedEntity.h"

#import "OReplicatedEntity+OReplicatedEntityExtensions.h"

static NSString * const kVConstraintsInitial          = @"V:|-10-";
static NSString * const kVConstraintsInitialWithTitle = @"V:|-44-";

static NSString * const kVConstraintsElementTopmost   = @"[%@(22)]";
static NSString * const kVConstraintsElement          = @"-%.f-[%@(22)]";
static NSString * const kHConstraintsLabel            = @"H:|-25-[%@]-25-|";
static NSString * const kHConstraintsTextField        = @"H:|-55-[%@]-55-|";

static NSString * const kVConstraintsTitleBanner      = @"V:|-(-1)-[titleBanner(39)]";
static NSString * const kHConstraintsTitleBanner      = @"H:|-(-1)-[titleBanner]-(-1)-|";
static NSString * const kVConstraintsTitle            = @"[%@(24)]-10-";
static NSString * const kHConstraintsTitle            = @"H:|-6-[%@]-6-|";
static NSString * const kHConstraintsTitleWithPhoto   = @"H:|-6-[%@]-6-[photoFrame(55)]-10-|";
static NSString * const kVConstraintsPhoto            = @"V:|-10-[photoFrame(55)]";
static NSString * const kVConstraintsPhotoPrompt      = @"V:|-3-[photoPrompt]-3-|";
static NSString * const kHConstraintsPhotoPrompt      = @"H:|-3-[photoPrompt]-3-|";

static NSString * const kVConstraintsLabel            = @"-%.f-[%@(22)]";
static NSString * const kVConstraintsTextField        = @"[%@(%.f)]";

static NSString * const kHConstraintsWithPhoto        = @"H:|-10-[%@(>=55)]-3-[%@]-6-[photoFrame]-10-|";
static NSString * const kHConstraints                 = @"H:|-10-[%@(>=55)]-3-[%@]-6-|";

static NSString * const kKeyPathPrefixDate = @"date";


@implementation OVisualConstraints

#pragma mark - Auxiliary methods

- (BOOL)elementsAreVisibleForKeyPath:(NSString *)keyPath
{
    BOOL elementsAreVisible = YES;
    
    if (_cell.entity) {
        NSArray *entityAttributeKeys = [[[_cell.entity entity] attributesByName] allKeys];
        
        if ([entityAttributeKeys containsObject:keyPath]) {
            id value = [_cell.entity valueForKey:keyPath];
            
            if (value && [value isKindOfClass:NSString.class]) {
                elementsAreVisible = ([value length] > 0);
            } else if (!value) {
                elementsAreVisible = NO;
            }
            
            elementsAreVisible = elementsAreVisible || [OState s].actionIsInput;
        }
    }
    
    return elementsAreVisible;
}


- (void)configureElementsIfNeededForKeyPath:(NSString *)keyPath
{
    id label = [_cell labelForKeyPath:keyPath];
    id textField = [_cell textFieldForKeyPath:keyPath];
    
    if ([self elementsAreVisibleForKeyPath:keyPath]) {
        if (label && [label isHidden]) {
            [label setHidden:NO];
        }
        
        if (textField && [textField isHidden]) {
            [textField setHidden:NO];
            
            id value = [_cell.entity valueForKey:keyPath];
            
            if (value && (![[textField text] length])) {
                if ([value isKindOfClass:NSString.class]) {
                    [textField setText:value];
                } else if ([value isKindOfClass:NSDate.class]) {
                    [textField setText:[value localisedDateString]];
                    ((UIDatePicker *)(((OTextField *)textField).inputView)).date = value;
                }
            }
        }
    } else {
        if (label && ![label isHidden]) {
            [label setHidden:YES];
        }
        
        if (textField && [textField isHidden]) {
            [textField setHidden:YES];
        }
    }
}


#pragma mark - Initialisation

- (id)initForTableViewCell:(OTableViewCell *)cell
{
    self = [super init];
    
    if (self) {
        _cell = cell;
        
        _unlabeledElementKeyPaths = [[NSMutableArray alloc] init];
        _labeledElementKeyPaths = [[NSMutableArray alloc] init];
    }
    
    return self;
}


#pragma mark - Adding constraints

- (void)addTitleConstraintsForKeyPath:(NSString *)keyPath
{
    _titleKeyPath = keyPath;
}


- (void)addLabeledTextFieldConstraintsForKeyPath:(NSString *)keyPath
{
    [_labeledElementKeyPaths addObject:keyPath];
}


- (void)addUnlabeledConstraintsForKeyPath:(NSString *)keyPath
{
    [_unlabeledElementKeyPaths addObject:keyPath];
}


#pragma mark - Generating visual constraints strings

- (NSArray *)titleConstraints
{
    NSMutableArray *constraints = [[NSMutableArray alloc] init];
    
    if (_titleKeyPath) {
        NSString *titleName = [_titleKeyPath stringByAppendingString:kElementSuffixTextField];
        
        [self configureElementsIfNeededForKeyPath:_titleKeyPath];
        
        [constraints addObject:kVConstraintsTitleBanner];
        [constraints addObject:kHConstraintsTitleBanner];
        
        if (_titleBannerHasPhoto) {
            [constraints addObject:[NSString stringWithFormat:kHConstraintsTitleWithPhoto, titleName]];
            [constraints addObject:kVConstraintsPhoto];
            [constraints addObject:kVConstraintsPhotoPrompt];
            [constraints addObject:kHConstraintsPhotoPrompt];
        } else {
            [constraints addObject:[NSString stringWithFormat:kHConstraintsTitle, titleName]];
        }
    }
    
    return constraints;
}


- (NSString *)labeledVerticalLabelConstraints
{
    NSString *constraints = _titleKeyPath ? kVConstraintsInitialWithTitle : kVConstraintsInitial;
    
    BOOL isTopmostLabel = YES;
    id precedingTextField = nil;
    
    for (NSString *keyPath in _labeledElementKeyPaths) {
        [self configureElementsIfNeededForKeyPath:keyPath];
        
        if ([self elementsAreVisibleForKeyPath:keyPath]) {
            NSString *constraint = nil;
            NSString *labelName = [keyPath stringByAppendingString:kElementSuffixLabel];
            
            if (isTopmostLabel) {
                constraint = [NSString stringWithFormat:kVConstraintsElementTopmost, labelName];
                isTopmostLabel = NO;
            } else {
                CGFloat padding = 0.f;
                
                if (precedingTextField && [precedingTextField isKindOfClass:OTextView.class]) {
                    padding = [(OTextView *)precedingTextField height] - [UIFont detailFieldHeight];
                }
                
                constraint = [NSString stringWithFormat:kVConstraintsLabel, padding, labelName];
            }
            
            precedingTextField = [_cell textFieldForKeyPath:keyPath];
            constraints = [constraints stringByAppendingString:constraint];
        }
    }
    
    return constraints;
}


- (NSString *)labeledVerticalTextFieldConstraints
{
    NSString *constraints = kVConstraintsInitial;
    
    if (_titleKeyPath) {
        NSString *titleName = [_titleKeyPath stringByAppendingString:kElementSuffixTextField];
        NSString *constraint = [NSString stringWithFormat:kVConstraintsTitle, titleName];
        
        constraints = [constraints stringByAppendingString:constraint];
    }
    
    for (NSString *keyPath in _labeledElementKeyPaths) {
        [self configureElementsIfNeededForKeyPath:keyPath];
        
        if ([self elementsAreVisibleForKeyPath:keyPath]) {
            id textField = [_cell textFieldForKeyPath:keyPath];
            
            CGFloat textFieldHeight = [UIFont detailFieldHeight];
            
            if ([textField isKindOfClass:OTextView.class]) {
                textFieldHeight = [(OTextView *)textField height];
            }
            
            NSString *textFieldName = [keyPath stringByAppendingString:kElementSuffixTextField];
            NSString *constraint = [NSString stringWithFormat:kVConstraintsTextField, textFieldName, textFieldHeight];
            
            constraints = [constraints stringByAppendingString:constraint];
        }
    }
    
    return constraints;
}


- (NSArray *)labeledHorizontalConstraints
{
    NSMutableArray *constraints = [[NSMutableArray alloc] init];
    
    NSInteger rowNumber = 0;
    
    for (NSString *keyPath in _labeledElementKeyPaths) {
        [self configureElementsIfNeededForKeyPath:keyPath];
        
        if ([self elementsAreVisibleForKeyPath:keyPath]) {
            NSString *labelName = [keyPath stringByAppendingString:kElementSuffixLabel];
            NSString *textFieldName = [keyPath stringByAppendingString:kElementSuffixTextField];
            NSString *constraint = nil;
            
            if (_titleBannerHasPhoto && (rowNumber++ < 2)) {
                constraint = [NSString stringWithFormat:kHConstraintsWithPhoto, labelName, textFieldName];
            } else {
                constraint = [NSString stringWithFormat:kHConstraints, labelName, textFieldName];
            }
            
            [constraints addObject:constraint];
        }
    }
    
    return constraints;
}


- (NSString *)unlabeledVerticalConstraints
{
    NSString *constraints = kVConstraintsInitial;
    
    BOOL isTopmostElement = YES;
    BOOL isBelowLabel = NO;
    
    for (NSString *keyPath in _unlabeledElementKeyPaths) {
        [self configureElementsIfNeededForKeyPath:keyPath];
        
        if ([self elementsAreVisibleForKeyPath:keyPath]) {
            NSString *constraint = nil;
            NSString *elementName = nil;
            
            if ([_cell labelForKeyPath:keyPath]) {
                elementName = [keyPath stringByAppendingString:kElementSuffixLabel];
            } else if ([_cell textFieldForKeyPath:keyPath]) {
                elementName = [keyPath stringByAppendingString:kElementSuffixTextField];
            }
            
            if (isTopmostElement) {
                constraint = [NSString stringWithFormat:kVConstraintsElementTopmost, elementName];
                isTopmostElement = NO;
            } else {
                CGFloat spacing = isBelowLabel ? kDefaultPadding / 3 : 1.f;
                constraint = [NSString stringWithFormat:kVConstraintsElement, spacing, elementName];
            }
            
            constraints = [constraints stringByAppendingString:constraint];
            isBelowLabel = [elementName hasSuffix:kElementSuffixLabel];
        }
    }
    
    return constraints;
}


- (NSArray *)unlabeledHorizontalConstraints
{
    NSMutableArray *constraints = [[NSMutableArray alloc] init];
    
    for (NSString *keyPath in _unlabeledElementKeyPaths) {
        [self configureElementsIfNeededForKeyPath:keyPath];
        
        if ([self elementsAreVisibleForKeyPath:keyPath]) {
            NSString *constraint = nil;
            
            if ([_cell labelForKeyPath:keyPath]) {
                NSString *elementName = [keyPath stringByAppendingString:kElementSuffixLabel];
                constraint = [NSString stringWithFormat:kHConstraintsLabel, elementName];
            } else if ([_cell textFieldForKeyPath:keyPath]) {
                NSString *elementName = [keyPath stringByAppendingString:kElementSuffixTextField];
                constraint = [NSString stringWithFormat:kHConstraintsTextField, elementName];
            }
            
            [constraints addObject:constraint];
        }
    }
    
    return constraints;
}


#pragma mark - Retrieving constraints

- (NSDictionary *)constraintsWithAlignmentOptions
{
    NSMutableDictionary *constraints = [[NSMutableDictionary alloc] init];
    
    NSNumber *allTrailingOptions = [NSNumber numberWithInteger:NSLayoutFormatAlignAllTrailing];
    NSNumber *noAlignmentOptions = [NSNumber numberWithInteger:0];
    
    if ([_labeledElementKeyPaths count]) {
        NSMutableArray *allTrailingConstraints = [[NSMutableArray alloc] init];
        [allTrailingConstraints addObject:[self labeledVerticalLabelConstraints]];
        
        NSMutableArray *nonAlignedConstraints = [[NSMutableArray alloc] init];
        [nonAlignedConstraints addObjectsFromArray:[self titleConstraints]];
        [nonAlignedConstraints addObject:[self labeledVerticalTextFieldConstraints]];
        [nonAlignedConstraints addObjectsFromArray:[self labeledHorizontalConstraints]];
        
        [constraints setObject:allTrailingConstraints forKey:allTrailingOptions];
        [constraints setObject:nonAlignedConstraints forKey:noAlignmentOptions];
    } else if ([_unlabeledElementKeyPaths count]) {
        NSMutableArray *nonAlignedConstraints = [[NSMutableArray alloc] init];
        [nonAlignedConstraints addObject:[self unlabeledVerticalConstraints]];
        [nonAlignedConstraints addObjectsFromArray:[self unlabeledHorizontalConstraints]];
        
        [constraints setObject:nonAlignedConstraints forKey:noAlignmentOptions];
    }
    
    //int i = 0;
    for (NSNumber *alignmentOptions in [constraints allKeys]) {
        NSArray *constraintsWithOptions = [constraints objectForKey:alignmentOptions];
        
        for (NSString *visualConstraints in constraintsWithOptions) {
            //OLogDebug(@"\nVisual constraint (%d): %@", i++, visualConstraints);
        }
    }
    
    return constraints;
}

@end
