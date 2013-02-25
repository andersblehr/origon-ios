//
//  OTableViewCellBlueprints.h
//  OrigoApp
//
//  Created by Anders Blehr on 22.02.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTableViewCellBlueprints : NSObject

+ (NSString *)titleKeyForReuseIdentifier:(NSString *)reuseIdentifier;
+ (NSString *)titleKeyForEntityClass:(Class)entityClass;
+ (NSArray *)detailKeysForReuseIdentifier:(NSString *)reuseIdentifier;
+ (NSArray *)detailKeysForEntityClass:(Class)entityClass;

+ (BOOL)titleHasPhotoForEntityClass:(Class)entityClass;
+ (BOOL)isKeyForMultiLineProperty:(NSString *)propertyKey;

@end
