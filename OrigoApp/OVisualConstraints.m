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

static NSString * const kVConstraintsInitial          = @"V:|-10-";
static NSString * const kVConstraintsInitialWithTitle = @"V:|-44-";

static NSString * const kVConstraintsElementTopmost   = @"[%@(22)]";
static NSString * const kVConstraintsElement          = @"-1-[%@(22)]";
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

static NSString * const kVConstraintsLabel            = @"-(%.f)-[%@(22)]";
static NSString * const kVConstraintsTextField        = @"[%@(%.f)]";

static NSString * const kHConstraintsTopmostWithPhoto = @"H:|-10-[%@(>=55)]-3-[%@]-6-[photoFrame]-10-|";
static NSString * const kHConstraints                 = @"H:|-10-[%@(>=55)]-3-[%@]-6-|";


@implementation OVisualConstraints

#pragma mark - Auxiliary methods

- (CGFloat)rowHeightForLineCount:(NSNumber *)lineCount
{
    NSUInteger numberOfLines = [lineCount intValue];
    
    if ([OState s].actionIsInput) {
        numberOfLines = MAX(2, numberOfLines);
    }
    
    return MAX(numberOfLines * [[UIFont detailFont] textViewLineHeight], [[UIFont detailFont] textFieldHeight]);
}


#pragma mark - Initialisation

- (id)init
{
    self = [super init];
    
    if (self) {
        _unlabeledElementNames = [[NSMutableArray alloc] init];
        _labeledElementNames = [[NSMutableArray alloc] init];
        _textViewLineCounts = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}


#pragma mark - Adding named constraints

- (void)addLabelConstraintsForName:(NSString *)name
{
    [_unlabeledElementNames addObject:[name stringByAppendingString:kNameSuffixLabel]];
}


- (void)addTextFieldConstraintsForName:(NSString *)name
{
    [_unlabeledElementNames addObject:[name stringByAppendingString:kNameSuffixTextField]];
}


- (void)addTitleConstraintsForName:(NSString *)name
{
    _titleName = [name stringByAppendingString:kNameSuffixTextField];
}


- (void)addLabeledTextFieldConstraintsForName:(NSString *)name
{
    [_labeledElementNames addObject:name];
    
    if (!_elementsAreLabeled) {
        _elementsAreLabeled = YES;
    }
}


- (void)addLabeledTextViewConstraintsForName:(NSString *)name lineCount:(NSUInteger)lineCount
{
    [self addLabeledTextFieldConstraintsForName:name];
    [_textViewLineCounts setObject:[NSNumber numberWithInteger:lineCount] forKey:name];
}


#pragma mark - Unlabeled element constraints

- (NSString *)verticalConstraintsForUnlabeledElements
{
    NSString *constraints = kVConstraintsInitial;
    
    BOOL isTopmostElement = YES;
    
    for (NSString *elementName in _unlabeledElementNames) {
        NSString *constraint = nil;
        
        if (isTopmostElement) {
            constraint = [NSString stringWithFormat:kVConstraintsElementTopmost, elementName];
            isTopmostElement = NO;
        } else {
            constraint = [NSString stringWithFormat:kVConstraintsElement, elementName];
        }
        
        constraints = [constraints stringByAppendingString:constraint];
    }
    
    return constraints;
}


- (NSArray *)horizontalConstraintsForUnlabeledELements
{
    NSMutableArray *constraints = [[NSMutableArray alloc] init];
    
    for (NSString *elementName in _unlabeledElementNames) {
        NSString *constraint = nil;
        
        if ([elementName hasSuffix:kNameSuffixLabel]) {
            constraint = [NSString stringWithFormat:kHConstraintsLabel, elementName];
        } else if ([elementName hasSuffix:kNameSuffixTextField]) {
            constraint = [NSString stringWithFormat:kHConstraintsTextField, elementName];
        }
        
        [constraints addObject:constraint];
    }
    
    return constraints;
}


#pragma mark - Labeled element constraints

- (NSArray *)titleConstraints
{
    NSMutableArray *constraints = [[NSMutableArray alloc] init];
    
    if (_titleName) {
        [constraints addObject:kVConstraintsTitleBanner];
        [constraints addObject:kHConstraintsTitleBanner];
        
        if (_titleBannerHasPhoto) {
            [constraints addObject:[NSString stringWithFormat:kHConstraintsTitleWithPhoto, _titleName]];
            [constraints addObject:kVConstraintsPhoto];
            [constraints addObject:kVConstraintsPhotoPrompt];
            [constraints addObject:kHConstraintsPhotoPrompt];
        } else {
            [constraints addObject:[NSString stringWithFormat:kHConstraintsTitle, _titleName]];
        }
    }
    
    return constraints;
}


- (NSString *)verticalLabelConstraintsForLabeledElements
{
    NSString *constraints = _titleName ? kVConstraintsInitialWithTitle : kVConstraintsInitial;
    
    BOOL isTopmostLabel = YES;
    NSNumber *precedingLineCount = nil;
    
    for (NSString *name in _labeledElementNames) {
        NSString *labelName = [name stringByAppendingString:kNameSuffixLabel];
        NSString *constraint = nil;
        
        if (isTopmostLabel) {
            constraint = [NSString stringWithFormat:kVConstraintsElementTopmost, labelName];
            isTopmostLabel = NO;
        } else {
            CGFloat paddingToPrecedingRow = 0.f;
            
            if (precedingLineCount) {
                paddingToPrecedingRow = [self rowHeightForLineCount:precedingLineCount] - [[UIFont detailFont] textFieldHeight];
            }
            
            constraint = [NSString stringWithFormat:kVConstraintsLabel, paddingToPrecedingRow, labelName];
        }
        
        constraints = [constraints stringByAppendingString:constraint];
        
        precedingLineCount = [_textViewLineCounts objectForKey:name];
    }
    
    return constraints;
}


- (NSString *)verticalTextFieldConstraintsForLabeledElements
{
    NSString *constraints = kVConstraintsInitial;
    
    if (_titleName) {
        NSString *constraint = [NSString stringWithFormat:kVConstraintsTitle, _titleName];
        
        constraints = [constraints stringByAppendingString:constraint];
    }
    
    for (NSString *name in _labeledElementNames) {
        NSNumber *lineCount = [_textViewLineCounts objectForKey:name];
        CGFloat rowHeight = lineCount ? [self rowHeightForLineCount:lineCount] : [[UIFont detailFont] textFieldHeight];
        
        NSString *textFieldName = [name stringByAppendingString:kNameSuffixTextField];
        NSString *constraint = [NSString stringWithFormat:kVConstraintsTextField, textFieldName, rowHeight];
        
        constraints = [constraints stringByAppendingString:constraint];
    }
    
    return constraints;
}


- (NSArray *)horizontalConstraintsForLabeledElements
{
    NSMutableArray *constraints = [[NSMutableArray alloc] init];
    
    BOOL isTopmostRow = YES;
    
    for (NSString *name in _labeledElementNames) {
        NSString *labelName = [name stringByAppendingString:kNameSuffixLabel];
        NSString *textFieldName = [name stringByAppendingString:kNameSuffixTextField];

        NSString *constraint = nil;
        
        if (isTopmostRow && _titleBannerHasPhoto) {
            constraint = [NSString stringWithFormat:kHConstraintsTopmostWithPhoto, labelName, textFieldName];
        } else {
            constraint = [NSString stringWithFormat:kHConstraints, labelName, textFieldName];
        }
        
        if (isTopmostRow) {
            isTopmostRow = NO;
        }

        [constraints addObject:constraint];
    }
    
    return constraints;
}


#pragma mark - Retrieving all constraints

- (NSArray *)constraints
{
    NSMutableArray *constraints = [[NSMutableArray alloc] init];
    
    if (_elementsAreLabeled) {
        [constraints addObjectsFromArray:[self titleConstraints]];
        [constraints addObject:[self verticalLabelConstraintsForLabeledElements]];
        [constraints addObject:[self verticalTextFieldConstraintsForLabeledElements]];
        [constraints addObjectsFromArray:[self horizontalConstraintsForLabeledElements]];
    } else {
        [constraints addObject:[self verticalConstraintsForUnlabeledElements]];
        [constraints addObjectsFromArray:[self horizontalConstraintsForUnlabeledELements]];
    }
    
    for (int i = 0; i < [constraints count]; i++) {
        OLogVerbose(@"\nVisual constraint (%d)>> %@", i, constraints[i]);
    }
    
    return constraints;
}

@end
