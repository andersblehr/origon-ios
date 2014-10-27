//
//  OTableViewCell+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 27/10/14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OTableViewCell+OrigoAdditions.h"


@implementation OTableViewCell (OrigoAdditions)

#pragma mark - Loading member data

- (void)loadMember:(id<OMember>)member inOrigo:(id<OOrigo>)origo includeRelations:(BOOL)includeRelations
{
    self.textLabel.text = origo ? [member displayNameInOrigo:origo] : member.name;
    
    NSArray *roles = [[origo membershipForMember:member] roles];
    
    if ([roles count]) {
        self.detailTextLabel.text = [[OUtil commaSeparatedListOfItems:roles conjoinLastItem:NO] stringByCapitalisingFirstLetter];
    } else {
        BOOL isCrossGenerational = [member isJuvenile] != [[OMeta m].user isJuvenile] || [member isJuvenile] != [[OState s].currentMember isJuvenile];
        
        if (isCrossGenerational && includeRelations) {
            self.detailTextLabel.textColor = [UIColor tonedDownTextColour];
            
            if ([member isJuvenile]) {
                self.detailTextLabel.text = [OUtil guardianInfoForMember:member];
            } else {
                self.detailTextLabel.text = origo ? [OUtil commaSeparatedListOfMembers:[member wardsInOrigo:origo] inOrigo:origo] : nil;
            }
        }
    }
    
    [self loadImageForMember:member];
}


#pragma mark - Loading cell images

- (void)loadImageForOrigo:(id<OOrigo>)origo
{
    if ([origo isOfType:kOrigoTypeResidence]) {
        self.imageView.image = [UIImage imageNamed:kIconFileHousehold];
    } else {
        self.imageView.image = [UIImage imageNamed:kIconFileOrigo]; // TODO: Origo specific icons?
    }
}


- (void)loadImageForMember:(id<OMember>)member
{
    if (member.photo) {
        self.imageView.image = [UIImage imageWithData:member.photo];
    } else {
        NSString *iconFileName = nil;
        
        if ([member isJuvenile]) {
            iconFileName = [member isMale] ? kIconFileBoy : kIconFileGirl;
        } else {
            iconFileName = [member isMale] ? kIconFileMan : kIconFileWoman;
        }
        
        if ([member isManaged]) {
            self.imageView.image = [UIImage imageNamed:iconFileName];
            
            if (![member isJuvenile]) {
                UIView *underline = [[UIView alloc] initWithFrame:CGRectMake(0.f, self.imageView.image.size.height + 1.f, self.imageView.image.size.width, 1.f)];
                underline.backgroundColor = [UIColor windowTintColour];
                [self.imageView addSubview:underline];
            }
        } else {
            [self loadTonedDownIconWithFileName:iconFileName];
        }
    }
}


- (void)loadTonedDownIconWithFileName:(NSString *)fileName
{
    self.imageView.tintColor = [UIColor tonedDownIconColour];
    self.imageView.image = [[UIImage imageNamed:fileName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

@end
