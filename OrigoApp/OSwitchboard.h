//
//  OSwitchboard.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSwitchboard : NSObject<UIActionSheetDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate> {
@private
    OOrigo *_origo;
    OMember *_member;
    NSInteger _requestType;
    
    NSMutableArray *_recipientTagsByServiceType;
    NSMutableArray *_recipientCandidatesByServiceType;
    NSArray *_recipientCandidates;
}

@property (strong, nonatomic, readonly) CTCarrier *carrier;

- (NSArray *)toolbarButtonsForOrigo:(OOrigo *)origo;
- (NSArray *)toolbarButtonsForMember:(OMember *)member;

@end
