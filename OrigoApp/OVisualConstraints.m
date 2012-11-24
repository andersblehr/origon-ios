//
//  OVisualConstraints.m
//  OrigoApp
//
//  Created by Anders Blehr on 18.11.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OVisualConstraints.h"

#import "UIFont+OFontExtensions.h"

#import "OLogging.h"
#import "OState.h"
#import "OTableViewCell.h"
#import "OTextField.h"
#import "OTextView.h"

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

static NSString * const kHConstraintsTopmostWithPhoto = @"H:|-10-[%@(>=55)]-3-[%@]-6-[photoFrame]-10-|";
static NSString * const kHConstraints                 = @"H:|-10-[%@(>=55)]-3-[%@]-6-|";


@implementation OVisualConstraints

#pragma mark - Initialisation

- (id)initForTableViewCell:(OTableViewCell *)cell
{
    self = [super init];
    
    if (self) {
        _cell = cell;
        
        _unlabeledElements = [[NSMutableArray alloc] init];
        _labeledElementKeyPaths = [[NSMutableArray alloc] init];
        
        _elementVisibility = [[NSMutableDictionary alloc] init];
        _textViewLineCounts = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}


#pragma mark - Adding constraints

- (void)addTitleConstraintsForKeyPath:(NSString *)keyPath
{
    _titleElement = [keyPath stringByAppendingString:kElementSuffixTextField];
}


- (void)addLabeledTextFieldConstraintsForKeyPath:(NSString *)keyPath visible:(BOOL)visible
{
    [_labeledElementKeyPaths addObject:keyPath];
    [_elementVisibility setObject:[NSNumber numberWithBool:visible] forKey:keyPath];

    ((UILabel *)[_cell labelForKeyPath:keyPath]).hidden = !visible;
    ((OTextField *)[_cell textFieldForKeyPath:keyPath]).hidden = !visible;
}


- (void)addLabeledTextViewConstraintsForKeyPath:(NSString *)keyPath lineCount:(NSUInteger)lineCount
{
    [self addLabeledTextFieldConstraintsForKeyPath:keyPath visible:YES];
    [self updateLabeledTextViewConstraintsForKeyPath:keyPath lineCount:lineCount];
}


- (void)addLabelConstraintsForKeyPath:(NSString *)keyPath
{
    [_unlabeledElements addObject:[keyPath stringByAppendingString:kElementSuffixLabel]];
}


- (void)addUnlabeledTextFieldConstraintsForKeyPath:(NSString *)keyPath
{
    [_unlabeledElements addObject:[keyPath stringByAppendingString:kElementSuffixTextField]];
}


#pragma mark - Updating constraints

- (void)updateLabeledTextViewConstraintsForKeyPath:(NSString *)keyPath lineCount:(NSInteger)lineCount
{
    [_textViewLineCounts setObject:[NSNumber numberWithInteger:lineCount] forKey:keyPath];
}


#pragma mark - Generating visual constraints strings

- (NSArray *)titleConstraints
{
    NSMutableArray *constraints = [[NSMutableArray alloc] init];
    
    if (_titleElement) {
        [constraints addObject:kVConstraintsTitleBanner];
        [constraints addObject:kHConstraintsTitleBanner];
        
        if (_titleBannerHasPhoto) {
            [constraints addObject:[NSString stringWithFormat:kHConstraintsTitleWithPhoto, _titleElement]];
            [constraints addObject:kVConstraintsPhoto];
            [constraints addObject:kVConstraintsPhotoPrompt];
            [constraints addObject:kHConstraintsPhotoPrompt];
        } else {
            [constraints addObject:[NSString stringWithFormat:kHConstraintsTitle, _titleElement]];
        }
    }
    
    return constraints;
}


- (NSString *)labeledVerticalLabelConstraints
{
    NSString *constraints = _titleElement ? kVConstraintsInitialWithTitle : kVConstraintsInitial;
    
    BOOL isTopmostLabel = YES;
    NSNumber *precedingLineCount = nil;
    
    for (NSString *keyPath in _labeledElementKeyPaths) {
        if ([[_elementVisibility objectForKey:keyPath] boolValue]) {
            NSString *labelElement = [keyPath stringByAppendingString:kElementSuffixLabel];
            NSString *constraint = nil;
            
            if (isTopmostLabel) {
                constraint = [NSString stringWithFormat:kVConstraintsElementTopmost, labelElement];
                isTopmostLabel = NO;
            } else {
                CGFloat paddingToPrecedingRow = 0.f;
                
                if (precedingLineCount) {
                    paddingToPrecedingRow = [OTextView heightForLineCount:[precedingLineCount intValue]] - [UIFont detailFieldHeight];
                }
                
                constraint = [NSString stringWithFormat:kVConstraintsLabel, paddingToPrecedingRow, labelElement];
            }
            
            constraints = [constraints stringByAppendingString:constraint];
            
            precedingLineCount = [_textViewLineCounts objectForKey:keyPath];
        }
    }
    
    return constraints;
}


- (NSString *)labeledVerticalTextFieldConstraints
{
    NSString *constraints = kVConstraintsInitial;
    
    if (_titleElement) {
        NSString *constraint = [NSString stringWithFormat:kVConstraintsTitle, _titleElement];
        
        constraints = [constraints stringByAppendingString:constraint];
    }
    
    for (NSString *keyPath in _labeledElementKeyPaths) {
        if ([[_elementVisibility objectForKey:keyPath] boolValue]) {
            NSNumber *lineCount = [_textViewLineCounts objectForKey:keyPath];
            CGFloat rowHeight = lineCount ? [OTextView heightForLineCount:[lineCount intValue]] : [UIFont detailFieldHeight];
            
            NSString *textFieldElement = [keyPath stringByAppendingString:kElementSuffixTextField];
            NSString *constraint = [NSString stringWithFormat:kVConstraintsTextField, textFieldElement, rowHeight];
            
            constraints = [constraints stringByAppendingString:constraint];
        }
    }
    
    return constraints;
}


- (NSArray *)labeledHorizontalConstraints
{
    NSMutableArray *constraints = [[NSMutableArray alloc] init];
    
    BOOL isTopmostRow = YES;
    
    for (NSString *keyPath in _labeledElementKeyPaths) {
        if ([[_elementVisibility objectForKey:keyPath] boolValue]) {
            NSString *labelElement = [keyPath stringByAppendingString:kElementSuffixLabel];
            NSString *textFieldElement = [keyPath stringByAppendingString:kElementSuffixTextField];
            
            NSString *constraint = nil;
            
            if (isTopmostRow && _titleBannerHasPhoto) {
                constraint = [NSString stringWithFormat:kHConstraintsTopmostWithPhoto, labelElement, textFieldElement];
            } else {
                constraint = [NSString stringWithFormat:kHConstraints, labelElement, textFieldElement];
            }
            
            if (isTopmostRow) {
                isTopmostRow = NO;
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
    
    for (NSString *element in _unlabeledElements) {
        NSString *constraint = nil;
        
        if (isTopmostElement) {
            constraint = [NSString stringWithFormat:kVConstraintsElementTopmost, element];
            isTopmostElement = NO;
        } else {
            CGFloat spacing = isBelowLabel ? kDefaultPadding / 3 : 1.f;
            constraint = [NSString stringWithFormat:kVConstraintsElement, spacing, element];
        }
        
        constraints = [constraints stringByAppendingString:constraint];
        isBelowLabel = [element hasSuffix:kElementSuffixLabel];
    }
    
    return constraints;
}


- (NSArray *)unlabeledHorizontalConstraints
{
    NSMutableArray *constraints = [[NSMutableArray alloc] init];
    
    for (NSString *element in _unlabeledElements) {
        NSString *constraint = nil;
        
        if ([element hasSuffix:kElementSuffixLabel]) {
            constraint = [NSString stringWithFormat:kHConstraintsLabel, element];
        } else if ([element hasSuffix:kElementSuffixTextField]) {
            constraint = [NSString stringWithFormat:kHConstraintsTextField, element];
        }
        
        [constraints addObject:constraint];
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
    } else if ([_unlabeledElements count]) {
        NSMutableArray *nonAlignedConstraints = [[NSMutableArray alloc] init];
        [nonAlignedConstraints addObject:[self unlabeledVerticalConstraints]];
        [nonAlignedConstraints addObjectsFromArray:[self unlabeledHorizontalConstraints]];
        
        [constraints setObject:nonAlignedConstraints forKey:noAlignmentOptions];
    }
    
    return constraints;
}

@end
