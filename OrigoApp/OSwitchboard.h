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
    id<OOrigo> _origo;
    id<OMember> _member;
    
    NSInteger _requestType;
    NSMutableArray *_recipientTagsByServiceType;
    NSMutableArray *_recipientCandidatesByServiceType;
    NSArray *_recipientCandidates;
    
    UIViewController *_presentingViewController;
}

@property (strong, nonatomic, readonly) CTCarrier *carrier;

- (NSArray *)toolbarButtonsForOrigo:(id<OOrigo>)origo;
- (NSArray *)toolbarButtonsForMember:(id<OMember>)member;

@end
