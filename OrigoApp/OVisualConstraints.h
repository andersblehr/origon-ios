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
    NSMutableArray *_unlabeledElementNames;
    NSMutableArray *_labeledElementNames;
    NSMutableDictionary *_textViewLineCounts;
    
    BOOL _elementsAreLabeled;
}

@property (nonatomic) BOOL titleBannerHasPhoto;

- (void)addLabelConstraintsForName:(NSString *)name;
- (void)addTextFieldConstraintsForName:(NSString *)name;

- (void)addTitleConstraintsForName:(NSString *)name;
- (void)addLabeledTextFieldConstraintsForName:(NSString *)name;
- (void)addLabeledTextViewConstraintsForName:(NSString *)name lineCount:(NSUInteger)lineCount;

- (NSArray *)constraints;

@end
