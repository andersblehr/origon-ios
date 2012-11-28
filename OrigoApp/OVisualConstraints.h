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
    
    NSString *_titleKeyPath;
    NSMutableArray *_labeledElementKeyPaths;
    NSMutableArray *_unlabeledElementKeyPaths;
}

@property (nonatomic) BOOL titleBannerHasPhoto;

- (id)initForTableViewCell:(OTableViewCell *)cell;

- (void)addTitleConstraintsForKeyPath:(NSString *)keyPath;
- (void)addLabeledTextFieldConstraintsForKeyPath:(NSString *)keyPath;
- (void)addUnlabeledConstraintsForKeyPath:(NSString *)keyPath;

- (NSDictionary *)constraintsWithAlignmentOptions;

@end
