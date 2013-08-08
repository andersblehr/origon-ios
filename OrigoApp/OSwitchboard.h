//
//  OSwitchboard.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface OSwitchboard : NSObject<UIActionSheetDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate> {
@private
    NSInteger _serviceRequest;
    OMember *_member;
    
    NSMutableArray *_emailRecipientCandidates;
    NSMutableArray *_textRecipientCandidates;
    NSMutableArray *_callRecipientCandidates;
    NSArray *_recipientCandidates;
}

@property (strong, nonatomic, readonly) CTCarrier *carrier;

- (NSArray *)toolbarButtonsWithEntity:(id)entity;

@end
