//
//  OTableViewCellLayout.h
//  OrigoApp
//
//  Created by Anders Blehr on 18.11.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

extern CGFloat const kDefaultTableViewCellHeight;
extern CGFloat const kDefaultCellPadding;
extern CGFloat const kMinimumCellPadding;

@class OTableViewCell;
@class OReplicatedEntity;

@interface OTableViewCellComposer : NSObject {
@private
    OReplicatedEntity *_entity;
    OTableViewCell *_cell;
    
    NSString *_titleKey;
    NSMutableArray *_labeledTextFieldKeys;
    NSMutableArray *_centredElementKeys;
}

@property (strong, nonatomic, readonly) NSString *titleKey;
@property (strong, nonatomic, readonly) NSArray *detailKeys;
@property (strong, nonatomic, readonly) NSArray *allKeys;
@property (nonatomic, readonly) BOOL titleBannerHasPhoto;

+ (CGFloat)cell:(OTableViewCell *)cell heightForEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity;

+ (BOOL)requiresTextViewForKey:(NSString *)key;

- (id)initForCell:(OTableViewCell *)cell;
- (void)composeForReuseIdentifier:(NSString *)reuseIdentifier;
- (void)composeForEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity;

- (NSDictionary *)constraintsWithAlignmentOptions;

@end
