//
//  OTableViewCellConstrainer.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTableViewCellConstrainer : NSObject {
@private
    OTableViewCellBlueprint *_blueprint;
    OTableViewCell *_cell;
    
    CGFloat _labelWidth;
}

- (id)initWithCell:(OTableViewCell *)cell blueprint:(OTableViewCellBlueprint *)blueprint;

- (NSDictionary *)constraintsWithAlignmentOptions;

@end
