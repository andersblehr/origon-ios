//
//  OPhoneNumberFormatter.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OPhoneNumberFormatter : NSObject {
@private
    NSInteger _optionalNestingLevel;
    NSInteger _groupNestingLevel;
    NSArray *_formats;
    
    NSString *_format;
    NSInteger _tokenOffset;
    NSInteger _canonicalOffset;
    NSString *_formattedPhoneNumber;
}

- (NSString *)formatPhoneNumber:(NSString *)phoneNumber;
- (NSString *)canonicalisePhoneNumber:(NSString *)phoneNumber;

@end
