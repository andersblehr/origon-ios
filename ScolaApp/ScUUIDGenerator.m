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
    CFUUIDRef newUUID = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef newUUIDAsCFString = CFUUIDCreateString(kCFAllocatorDefault, newUUID);
    NSString *UUID = [[NSString stringWithString:(__bridge NSString *)newUUIDAsCFString] lowercaseString];
    
    CFRelease(newUUID);
    CFRelease(newUUIDAsCFString);
    
    return UUID;
}

@end
