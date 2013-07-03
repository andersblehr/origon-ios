//
//  OTextField.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

extern CGFloat const kTextInset;

@class OTableViewCell;
@protocol OTableViewInputDelegate;

@interface OTextField : UITextField {
@private
    BOOL _isTitle;
    BOOL _hasEmphasis;
    BOOL _didPickDate;
    
    NSString *_cachedText;

    id<OTableViewInputDelegate> _inputDelegate;
}

@property (strong, nonatomic, readonly) NSString *key;
@property (strong, nonatomic) NSDate *date;

@property (nonatomic) BOOL isTitle;
@property (nonatomic) BOOL hasEmphasis;

- (id)initWithKey:(NSString *)key delegate:(id)delegate;

- (BOOL)isDateField;
- (BOOL)hasValue;
- (BOOL)hasValidValue;

- (id)objectValue;
- (NSString *)textValue;

- (void)indicatePendingEvent:(BOOL)isPending;

@end
