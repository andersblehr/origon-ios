//
//  OVisualConstraints.h
//  OrigoApp
//
//  Created by Anders Blehr on 18.11.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OVisualConstraints : NSObject {
@private
    NSString *_titleName;
    NSMutableArray *_labeledElementNames;
    NSMutableArray *_unlabeledElementNames;
    
    NSMutableDictionary *_elementVisibility;
    NSMutableDictionary *_textViewLineCounts;
}

@property (nonatomic) BOOL titleBannerHasPhoto;

- (void)addTitleConstraintsForName:(NSString *)name;
- (void)addLabeledTextFieldConstraintsForName:(NSString *)name;
- (void)addLabeledTextViewConstraintsForName:(NSString *)name lineCount:(NSUInteger)lineCount;
- (void)addLabelConstraintsForName:(NSString *)name;
- (void)addUnlabaledTextFieldConstraintsForName:(NSString *)name;

- (void)updateLabeledTextViewConstraintsForName:(NSString *)name lineCount:(NSInteger)lineCount;

- (BOOL)elementsAreLabeled;
- (BOOL)elementsAreUnlabeled;

- (NSString *)labeledAlignmentConstraints;
- (NSArray *)labeledSizeConstraints;
- (NSArray *)unlabeledConstraints;

@end
