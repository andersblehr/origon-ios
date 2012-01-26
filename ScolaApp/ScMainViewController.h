//
//  ScMainViewController.h
//  ScolaApp
//
//  Created by Anders Blehr on 29.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ScMainViewController : UIViewController {
@private
    NSMutableArray *iconSections;
}

@property (weak, nonatomic) IBOutlet UIImageView *darkLinenView;

- (IBAction)showInfo:(id)sender;

@end
