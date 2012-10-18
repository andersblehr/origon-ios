//
//  OUUIDGenerator.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OUUIDGenerator.h"

@implementation OUUIDGenerator

+ (NSString *)generateUUID
{
    CFUUIDRef UUIDRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef UUIDAsCFStringRef = CFUUIDCreateString(kCFAllocatorDefault, UUIDRef);
    
    NSString *UUID = [[NSString stringWithString:(__bridge NSString *)UUIDAsCFStringRef] lowercaseString];
    
    CFRelease(UUIDRef);
    CFRelease(UUIDAsCFStringRef);
    
    return UUID;
}

@end
