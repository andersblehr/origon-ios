//
//  UITableView+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "UITableView+OrigoAdditions.h"

NSInteger const kSectionIndexMinimumDisplayRowCount = 11;

static UIView *_dimmerView = nil;
static NSInteger _sectionIndexMinimumDisplayRowCount = 0;


@implementation UITableView (OrigoAdditions)

#pragma mark - Auxiliary methods

- (id)cellWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate
{
    OTableViewCell *cell = [self dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (cell) {
        if (cell.isInputCell) {
            cell.inputCellDelegate = delegate;
        } else if (!cell.editable) {
            cell.textLabel.text = nil;
            cell.detailTextLabel.text = nil;
            cell.imageView.image = nil;
            cell.destinationId = nil;
            
            for (UIView *subview in cell.imageView.subviews) {
                [subview removeFromSuperview];
            }
        }
    } else {
        cell = [[OTableViewCell alloc] initWithStyle:style reuseIdentifier:reuseIdentifier delegate:delegate];
    }
    
    
    return cell;
}


#pragma mark - Cell instantiation

- (id)listCellWithStyle:(UITableViewCellStyle)style data:(id)data delegate:(id)delegate
{
    OTableViewCell *cell = [self cellWithStyle:style reuseIdentifier:[kReuseIdentifierList stringByAppendingFormat:@":%d", (short)style] delegate:delegate];
    
    if ([data conformsToProtocol:@protocol(OEntity)]) {
        cell.entity = data;
    }
    
    return cell;
}


- (id)editableListCellWithData:(id)data delegate:(id)delegate
{
    return [self listCellWithStyle:UITableViewCellStyleDefault data:data delegate:delegate];
}


- (id)inputCellWithEntity:(id<OEntity>)entity delegate:(id)delegate
{
    OTableViewCell *cell = [self dequeueReusableCellWithIdentifier:NSStringFromClass([entity entityClass])];
    
    if (cell) {
        cell.inputCellDelegate = delegate;
    } else {
        cell = [[OTableViewCell alloc] initWithEntity:entity delegate:delegate];
    }
    
    return cell;
}


- (id)inputCellWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate
{
    return [self cellWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier delegate:delegate];
}


#pragma mark - Dimming & undimming

- (void)dim
{
    if (self.sectionIndexMinimumDisplayRowCount) {
        _sectionIndexMinimumDisplayRowCount = self.sectionIndexMinimumDisplayRowCount;
        self.sectionIndexMinimumDisplayRowCount = NSIntegerMax;
        [self reloadSectionIndexTitles];
    }
    
    _dimmerView = [[UIView alloc] initWithFrame:self.bounds];
    _dimmerView.backgroundColor = [UIColor dimmedViewColour];
    _dimmerView.alpha = 0.f;
    
    [self addSubview:_dimmerView];
    
    [UIView animateWithDuration:kFadeAnimationDuration animations:^{
        _dimmerView.alpha = 1.f;
    } completion:^(BOOL finished) {
        _dimmerView.userInteractionEnabled = YES;
    }];
    
    self.scrollEnabled = NO;
}


- (void)undim
{
    if (_sectionIndexMinimumDisplayRowCount) {
        self.sectionIndexMinimumDisplayRowCount = _sectionIndexMinimumDisplayRowCount;
        [self reloadSectionIndexTitles];
    }
    
    [UIView animateWithDuration:kFadeAnimationDuration animations:^{
        _dimmerView.alpha = 0.f;
    } completion:^(BOOL finished) {
        _dimmerView.userInteractionEnabled = NO;
    }];
    
    [_dimmerView removeFromSuperview];
    _dimmerView = nil;
    
    self.scrollEnabled = YES;
}


@end
