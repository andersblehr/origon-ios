//
//  ScUUIDGenerator.m
//  ScolaApp
//
//  Created by Anders Blehr on 22.02.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScUUIDGenerator.h"

@implementation ScUUIDGenerator

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
