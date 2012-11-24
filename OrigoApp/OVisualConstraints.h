//
//  OVisualConstraints.h
//  OrigoApp
//
//  Created by Anders Blehr on 18.11.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OTableViewCell;

@interface OVisualConstraints : NSObject {
@private
    OTableViewCell *_cell;
    
    NSString *_titleElement;
    NSMutableArray *_labeledElementKeyPaths;
    NSMutableArray *_unlabeledElements;
    
    NSMutableDictionary *_elementVisibility;
    NSMutableDictionary *_textViewLineCounts;
}

@property (nonatomic) BOOL titleBannerHasPhoto;

- (id)initForTableViewCell:(OTableViewCell *)cell;

- (void)addTitleConstraintsForKeyPath:(NSString *)keyPath;
- (void)addLabeledTextFieldConstraintsForKeyPath:(NSString *)keyPath visible:(BOOL)visible;
- (void)addLabeledTextViewConstraintsForKeyPath:(NSString *)keyPath lineCount:(NSUInteger)lineCount;
- (void)addLabelConstraintsForKeyPath:(NSString *)keyPath;
- (void)addUnlabeledTextFieldConstraintsForKeyPath:(NSString *)keyPath;

- (void)updateLabeledTextViewConstraintsForKeyPath:(NSString *)keyPath lineCount:(NSInteger)lineCount;

- (NSDictionary *)constraintsWithAlignmentOptions;

@end
