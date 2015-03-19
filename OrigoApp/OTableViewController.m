//
//  OTableViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OTableViewController.h"

static NSString * const kViewControllerSuffixList = @"ListViewController";
static NSString * const kViewControllerSuffixPicker = @"PickerViewController";
static NSString * const kViewControllerSuffixDefault = @"ViewController";

static NSString * const kProtocolTel = @"tel://";

static CGFloat const kInitialHeadroomHeight = 28.f;
static CGFloat const kPlainTableViewHeaderHeight = 24.f;
static CGFloat const kFooterHeadroom = 6.f;
static CGFloat const kEmptyHeaderHeight = 14.f;
static CGFloat const kEmptyFooterHeight = 14.f;
static CGFloat const kEliminatedHeaderFooterHeight = 0.01f;

static NSInteger const kInputSectionKey = 0;

static BOOL _needsReinstantiateRootViewController;
static UIViewController * _reinstantiatedRootViewController;


@interface OTableViewController () <UITextFieldDelegate, UITextViewDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate> {
@private
    BOOL _didJustLoad;
    BOOL _didInitialise;
    BOOL _isUsingSectionIndexTitles;
    BOOL _shouldBeginEditingTitleView;
    
    Class _entityClass;
    NSInteger _inputSectionKey;
    NSMutableArray *_sectionKeys;
    NSMutableDictionary *_sectionData;
    NSMutableDictionary *_sectionCounts;
    NSMutableDictionary *_sectionHeaderLabels;
    NSMutableDictionary *_sectionFooterLabels;
    NSMutableArray *_sectionIndexTitles;
    
    NSMutableArray *_titleSegmentTitles;
    UISegmentedControl *_titleSegments;
    UISegmentedControl *_segmentedHeader;
    NSInteger _segmentedHeaderSectionKey;
    
    OTableViewCell *_inlineCell;
    UIGestureRecognizer *_inlineCellCancelRecogniser;
    
    NSIndexPath *_selectedIndexPath;
    OActivityIndicator *_activityIndicator;
    
    UIBarButtonItem *_nextButton;
    UIBarButtonItem *_doneButton;
    UIBarButtonItem *_cancelButton;
    
    id<OTableViewController> _instance;
}

@end


@implementation OTableViewController

@synthesize identifier = _identifier;
@synthesize target = _target;
@synthesize returnData = _returnData;


#pragma mark - Comparison delegation

static NSInteger compareObjects(id object1, id object2, void *context)
{
    return [(__bridge id)context compareObject:object1 toObject:object2];
}


#pragma mark - Auxiliary methods

- (BOOL)isEntityViewController
{
    if (!_entityClass) {
        if (![self isListViewController] && ![self isPickerViewController]) {
            NSString *viewControllerName = NSStringFromClass([self class]);
            _entityClass = NSClassFromString([viewControllerName substringToIndex:[viewControllerName rangeOfString:kViewControllerSuffixDefault].location]);
        }
    }
    
    return _entityClass != NULL;
}


- (BOOL)isListViewController
{
    return [NSStringFromClass([self class]) hasSuffix:kViewControllerSuffixList];
}


- (BOOL)isPickerViewController
{
    return [NSStringFromClass([self class]) hasSuffix:kViewControllerSuffixPicker];
}


- (void)initialiseInstance
{
    if ([[OMeta m] userIsAllSet] || _isModal) {
        if ([self isEntityViewController]) {
            _state.action = _isModal ? kActionRegister : kActionDisplay;
        } else if ([self isListViewController]) {
            _state.action = kActionList;
        } else if ([self isPickerViewController]) {
            _state.action = kActionPick;
        } else {
            _state.action = kActionDisplay;
        }
        
        [_instance loadState];
        [_instance loadData];
        
        for (NSNumber *sectionKey in [_sectionData allKeys]) {
            _sectionCounts[sectionKey] = @([_sectionData[sectionKey] count]);
        }
        
        if (_tableView && !_didJustLoad) {
            [_tableView reloadData];
        }
            
        _didInitialise = YES;
    } else {
        _state.action = kActionLoad;
        _state.target = kTargetUser;
    }
}


- (NSArray *)sortedArrayWithData:(id)data forSectionWithKey:(NSInteger)sectionKey
{
    NSArray *unsortedArray = [data isKindOfClass:[NSSet class]] ? [data allObjects] : data;
    NSArray *sortedArray = nil;
    
    BOOL instanceCanCompare = NO;
    
    if ([_instance respondsToSelector:@selector(canCompareObjectsInSectionWithKey:)]) {
        instanceCanCompare = [_instance canCompareObjectsInSectionWithKey:sectionKey];
    }
    
    if (instanceCanCompare) {
        sortedArray = [unsortedArray sortedArrayUsingFunction:compareObjects context:(__bridge void *)_instance];
    } else if ([_instance respondsToSelector:@selector(sortKeyForSectionWithKey:)]) {
        NSString *sortKey = [_instance sortKeyForSectionWithKey:sectionKey];
        
        if (sortKey) {
            sortedArray = [unsortedArray sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:sortKey ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
        }
    }
    
    return sortedArray ? sortedArray : unsortedArray;
}


- (NSInteger)sectionKeyForSectionNumber:(NSInteger)sectionNumber
{
    return [_sectionKeys[sectionNumber] integerValue];
}


- (NSInteger)sectionNumberForSectionKey:(NSInteger)sectionKey
{
    return [_sectionKeys indexOfObject:@(sectionKey)];
}


- (BOOL)shouldEliminateSpaceBelowSection:(NSInteger)section
{
    BOOL shouldEliminate = NO;
    
    if ([self isEntityViewController] && [_sectionKeys count] > 1) {
        if (section == [self sectionNumberForSectionKey:kInputSectionKey]) {
            OInputCellBlueprint *blueprint = [(id<OInputCellDelegate>)_instance inputCellBlueprint];
            
            shouldEliminate = blueprint.titleKey && ![blueprint.detailKeys count] && ![_instance hasHeaderForSectionWithKey:[self sectionKeyForSectionNumber:section + 1]];
        }
    }
    
    return shouldEliminate;
}


- (BOOL)shouldEliminateSpaceAboveSection:(NSInteger)section
{
    BOOL shouldEliminate = NO;
    
    if ([self isEntityViewController]) {
        NSInteger inputSection = [self sectionNumberForSectionKey:kInputSectionKey];
        
        if (section == inputSection + 1) {
            shouldEliminate = [self shouldEliminateSpaceBelowSection:inputSection];
        }
    }
    
    return shouldEliminate;
}


- (void)reloadHeaderForSection:(NSInteger)section
{
    [self reloadHeaderForSectionWithKey:[self sectionKeyForSectionNumber:section]];
}


- (void)reloadFooterForSection:(NSInteger)section
{
    [self reloadFooterForSectionWtihKey:[self sectionKeyForSectionNumber:section]];
}


- (void)setTableViewFooterViewIfNeeded
{
    if ([_sectionKeys count]) {
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        
        if (_usesPlainTableViewStyle) {
            _tableView.backgroundColor = [UIColor whiteColor];
        }
    } else if ([_instance respondsToSelector:@selector(emptyTableViewFooterText)]) {
        NSString *footerText = [_instance emptyTableViewFooterText];

        if ([footerText hasValue]) {
            UIView *tableFooterView = [self footerViewWithText:footerText];;
            UILabel *tableFooterLabel = tableFooterView.subviews[0];
            
            CGRect tableFooterViewFrame = tableFooterView.frame;
            tableFooterViewFrame.size.height += kEmptyHeaderHeight;
            tableFooterView.frame = tableFooterViewFrame;
            
            CGRect tableFooterLabelFrame = tableFooterLabel.frame;
            tableFooterLabelFrame.origin.y = kEmptyHeaderHeight;
            tableFooterLabel.frame = tableFooterLabelFrame;
            
            _tableView.tableFooterView = tableFooterView;
        }
        
        if (_usesPlainTableViewStyle) {
            _tableView.backgroundColor = [UIColor tableViewBackgroundColour];
        }
    }
}


- (void)setToolbarItemsIfApplicable
{
    if (!self.isModal) {
        NSMutableArray *toolbarItems = [NSMutableArray array];
        
        BOOL hasSendTextButton = NO;
        BOOL hasCallButton = NO;
        BOOL hasSendEmailButton = NO;
        
        if ([MFMessageComposeViewController canSendText] || [OMeta deviceIsSimulator]) {
            if ([_instance respondsToSelector:@selector(toolbarHasSendTextButton)]) {
                hasSendTextButton = [_instance toolbarHasSendTextButton];
            }
        }
        
        BOOL hasSignal = [[OMeta m].carrier.mobileNetworkCode hasValue];
        BOOL deviceCanMakeCall = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:kProtocolTel]];
        
        if ((hasSignal && deviceCanMakeCall) || [OMeta deviceIsSimulator]) {
            if ([_instance respondsToSelector:@selector(toolbarHasCallButton)]) {
                hasCallButton = [_instance toolbarHasCallButton];
            }
        }
        
        if ([MFMailComposeViewController canSendMail]) {
            if ([_instance respondsToSelector:@selector(toolbarHasSendEmailButton)]) {
                hasSendEmailButton = [_instance toolbarHasSendEmailButton];
            }
        }
        
        if (hasSendTextButton || hasCallButton || hasSendEmailButton) {
            [toolbarItems addObject:[UIBarButtonItem flexibleSpace]];
            
            if (hasSendTextButton) {
                [toolbarItems addObject:[UIBarButtonItem sendTextButtonWithTarget:_instance]];
                [toolbarItems addObject:[UIBarButtonItem flexibleSpace]];
            }
            
            if (hasCallButton) {
                [toolbarItems addObject:[UIBarButtonItem callButtonWithTarget:_instance]];
                [toolbarItems addObject:[UIBarButtonItem flexibleSpace]];
            }
            
            if (hasSendEmailButton) {
                [toolbarItems addObject:[UIBarButtonItem sendEmailButtonWithTarget:_instance]];
                [toolbarItems addObject:[UIBarButtonItem flexibleSpace]];
            }
        }
        
        self.toolbarItems = [toolbarItems count] ? toolbarItems : nil;
    }
    
    BOOL toolbarHidden = !self.toolbarItems;
    
    if (self.navigationController.toolbarHidden != toolbarHidden) {
        [self.navigationController setToolbarHidden:toolbarHidden animated:YES];
    }
}


- (void)inputFieldDidBecomeFirstResponder:(OInputField *)inputField
{
    if ([self actionIs:kActionDisplay]) {
        [self toggleEditMode];
    }
    
    _inputCell.inputField = inputField;
    
    if ([_inputCell nextInputField]) {
        if (_nextButton) {
            self.navigationItem.rightBarButtonItem = _nextButton;
        }
        
        if (!inputField.supportsMultiLineText) {
            inputField.returnKeyType = UIReturnKeyNext;
        }
    } else {
        if (_doneButton) {
            self.navigationItem.rightBarButtonItem = _doneButton;
        }
        
        if (!inputField.supportsMultiLineText) {
            if ([OValidator isPasswordKey:inputField.key]) {
                inputField.returnKeyType = UIReturnKeyGo;
            } else {
                inputField.returnKeyType = UIReturnKeyDone;
            }
        }
    }
}


- (void)setEditingTitle:(BOOL)editing
{
    static UIBarButtonItem *leftBarButtonItem = nil;
    static NSArray *rightBarButtonItems = nil;
    
    if (editing) {
        leftBarButtonItem = self.navigationItem.leftBarButtonItem;
        rightBarButtonItems = self.navigationItem.rightBarButtonItems;
        
        if (!self.isModal || [_titleView.title hasValue]) {
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self action:@selector(didCancelEditingTitle)];
        }
        
        self.navigationItem.rightBarButtonItems = @[[UIBarButtonItem doneButtonWithTitle:NSLocalizedString(@"Use", @"") target:self action:@selector(didFinishEditingTitle)]];
        
        [_tableView dim];
    } else {
        self.navigationItem.leftBarButtonItem = leftBarButtonItem;
        self.navigationItem.rightBarButtonItems = rightBarButtonItems;
        
        [_tableView undim];
        
        if ([self actionIs:kActionRegister]) {
            [_inputCell resumeFirstResponder];
        }
    }
}


- (void)finishInlineEditing
{
    OInputField *inlineField = [_inlineCell inlineField];
    [inlineField resignFirstResponder];
    inlineField.editable = NO;
    
    if ([_instance respondsToSelector:@selector(didFinishEditingInlineField:)]) {
        [_instance didFinishEditingInlineField:[_inlineCell inlineField]];
    }
    
    [self.view removeGestureRecognizer:_inlineCellCancelRecogniser];
    
    _inlineCell.selectable = YES;
    _inlineCell = nil;
    _inlineCellCancelRecogniser = nil;
}


#pragma mark - Header & footer handling & delegation

- (BOOL)instanceHasHeaderForSectionWithKey:(NSInteger)sectionKey
{
    BOOL hasHeader = NO;
    
    if ([_instance respondsToSelector:@selector(hasHeaderForSectionWithKey:)]) {
        hasHeader = [_instance hasHeaderForSectionWithKey:sectionKey];
    } else {
        hasHeader = [self sectionNumberForSectionKey:sectionKey] > 0;
    }
    
    return hasHeader || _isUsingSectionIndexTitles;
}


- (BOOL)instanceHasFooterForSectionWithKey:(NSInteger)sectionKey
{
    BOOL hasFooter = NO;
    
    if ([_instance respondsToSelector:@selector(hasFooterForSectionWithKey:)]) {
        hasFooter = [_instance hasFooterForSectionWithKey:sectionKey];
    }
    
    return hasFooter;
}


- (id)footerForSectionWithKey:(NSInteger)sectionKey
{
    id footer = nil;
    
    if ([_instance respondsToSelector:@selector(footerContentForSectionWithKey:)]) {
        footer = [_instance footerContentForSectionWithKey:sectionKey];
    }
    
    return footer;
}


- (CGFloat)footerHeightWithText:(NSString *)footerText
{
    CGFloat textHeight = [footerText lineCountWithFont:[UIFont footerFont] maxWidth:[OMeta screenWidth] - 2 * kContentInset] * [UIFont footerFont].lineHeight;
    
    return textHeight + 2 * kDefaultCellPadding;
}


- (UIView *)segmentedHeaderViewWithSegmentTitles:(NSArray *)segmentTitles inSection:(NSInteger)section
{
    CGFloat leftmostWidth = 0.f;
    CGFloat maxWidth = 0.f;
    
    for (NSString *segmentTitle in segmentTitles) {
        CGFloat titleWidth = [segmentTitle sizeWithFont:[UIFont headerFont] maxWidth:CGFLOAT_MAX].width;
        
        if (!leftmostWidth) {
            leftmostWidth = titleWidth;
            maxWidth = titleWidth;
        } else {
            maxWidth = MAX(maxWidth, titleWidth);
        }
    }
    
    CGFloat headerViewHeight = [self tableView:_tableView heightForHeaderInSection:section];
    CGFloat headerHeight = [[UIFont headerFont] headerHeight];
    CGFloat headroom = headerViewHeight - headerHeight;
    
    _segmentedHeader = [[UISegmentedControl alloc] initWithItems:segmentTitles];
    _segmentedHeader.frame = CGRectMake(kDefaultCellPadding - (maxWidth - leftmostWidth) / 2.f, headroom, _segmentedHeader.frame.size.width, headerHeight);
    _segmentedHeader.tintColor = [UIColor clearColor];
    _segmentedHeader.selectedSegmentIndex = _selectedHeaderSegment;
    [_segmentedHeader setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor headerTextColour], NSFontAttributeName: [UIFont headerFont]} forState:UIControlStateSelected];
    [_segmentedHeader setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor], NSFontAttributeName: [UIFont headerFont]} forState:UIControlStateNormal];
    [_segmentedHeader addTarget:self action:@selector(didSelectHeaderSegment) forControlEvents:UIControlEventValueChanged];
    
    UIView *segmentedHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, [OMeta screenWidth], headerViewHeight)];
    segmentedHeaderView.backgroundColor = [UIColor clearColor];
    [segmentedHeaderView addSubview:_segmentedHeader];
    
    return segmentedHeaderView;
}


- (UIView *)footerViewWithText:(NSString *)footerText
{
    CGFloat footerHeight = [self footerHeightWithText:footerText];
    CGRect footerFrame = CGRectMake(0.f, 0.f, [OMeta screenWidth], footerHeight);
    CGRect labelFrame = CGRectMake(kContentInset, 0.f, [OMeta screenWidth] - 2 * kContentInset, footerHeight + kFooterHeadroom);
    
    UIView *footerView = [[UIView alloc] initWithFrame:footerFrame];
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:labelFrame];
    
    footerLabel.backgroundColor = [UIColor clearColor];
    footerLabel.font = [UIFont footerFont];
    footerLabel.numberOfLines = 0;
    footerLabel.text = footerText;
    footerLabel.textAlignment = NSTextAlignmentCenter;
    footerLabel.textColor = [UIColor footerTextColour];
    
    [footerView addSubview:footerLabel];
    
    return footerView;
}


#pragma mark - Selector implementations

- (void)refresh
{
    [[OMeta m].replicator refreshWithRefreshHandler:self];
}


- (void)didSelectHeaderSegment
{
    _selectedHeaderSegment = _segmentedHeader.selectedSegmentIndex;
    
    [self reloadSectionWithKey:_segmentedHeaderSectionKey];
}


- (void)didCancelEditing
{
    if ([self actionIs:kActionEdit]) {
        [_inputCell readData];
        [self toggleEditMode];
    } else {
        _didCancel = !_cancelImpliesSkip;
        
        if (_didCancel) {
            if ([self actionIs:kActionRegister]) {
                [self.entity expire];
            }
            
            if (_titleView.editing) {
                _titleView.editing = NO;
            }
            
            [_dismisser dismissModalViewController:self];
        } else {
            [_inputCell clearInputFields];
            [_inputCell processInputShouldValidate:NO];
        }
    }
}


- (void)didFinishEditing
{
    if ([self actionIs:kActionInput]) {
        if (_isModal && [self isEntityViewController]) {
            _returnData = _entity;
        }
        
        [_inputCell processInputShouldValidate:YES];
    } else {
        [_dismisser dismissModalViewController:self];
    }
}


- (void)moveToNextInputField
{
    [[_inputCell nextInputField] becomeFirstResponder];
}


- (void)didCancelEditingTitle
{
    _titleView.didCancel = YES;
}


- (void)didFinishEditingTitle
{
    _titleView.editing = NO;
}


#pragma mark - Preceding view controller access

- (OTableViewController *)precedingViewController
{
    OTableViewController *precedingViewController = nil;
    
    if (self.navigationController) {
        precedingViewController = self.navigationController.viewControllers[[self.navigationController.viewControllers indexOfObject:self] - 1];
    }
    
    return precedingViewController;
}


#pragma mark - State introspection

- (BOOL)actionIs:(id)action
{
    return [_state actionIs:action];
}


- (BOOL)targetIs:(id)target
{
    return [_state targetIs:target];
}


- (BOOL)aspectIs:(id)aspect
{
    return [_state aspectIs:aspect];
}


#pragma mark - Managing section data

- (void)setDataForInputSection
{
    [self setData:self.target forSectionWithKey:kInputSectionKey];
}


- (void)setData:(id)data forSectionWithKey:(NSInteger)sectionKey
{
    if ([data conformsToProtocol:@protocol(NSFastEnumeration)]) {
        _sectionData[@(sectionKey)] = [[self sortedArrayWithData:data forSectionWithKey:sectionKey] mutableCopy];
    } else if (data) {
        if (sectionKey == kInputSectionKey) {
            _inputSectionKey = sectionKey;
            
            if (_entity) {
                _sectionData[@(sectionKey)] = [NSMutableArray arrayWithObject:_entity];
            } else {
                _sectionData[@(sectionKey)] = [NSMutableArray arrayWithObject:data];
            }
        } else {
            _sectionData[@(sectionKey)] = [NSMutableArray arrayWithObject:data];
        }
    }
    
    if ([_sectionData[@(sectionKey)] count]) {
        if (![_sectionKeys containsObject:@(sectionKey)]) {
            [_sectionKeys addObject:@(sectionKey)];
            [_sectionKeys sortUsingSelector:@selector(compare:)];
        }
    }
}


- (void)appendData:(id)data toSectionWithKey:(NSInteger)sectionKey
{
    if (sectionKey == _inputSectionKey) {
        _inputSectionKey = NSNotFound;
        _entity = nil;
    }
    
    if ([data isKindOfClass:[NSArray class]] || [data isKindOfClass:[NSSet class]]) {
        [_sectionData[@(sectionKey)] addObjectsFromArray:[self sortedArrayWithData:data forSectionWithKey:sectionKey]];
    } else if (data && ![_sectionData[@(sectionKey)] containsObject:data]) {
        [_sectionData[@(sectionKey)] addObject:data];
    }
}


- (void)setData:(NSArray *)data sectionIndexLabelKey:(NSString *)sectionIndexLabelKey
{
    static NSInteger sectionKey;
    static NSString *labelKey = nil;
    
    if (sectionIndexLabelKey) {
        sectionKey = 0;
        
        if (_usesSectionIndexTitles) {
            _isUsingSectionIndexTitles = [data count] >= kSectionIndexMinimumDisplayRowCount;
        }
        
        if (_isUsingSectionIndexTitles) {
            _sectionIndexTitles = [NSMutableArray array];
            
            labelKey = sectionIndexLabelKey;
            
            [self setData:data sectionIndexLabelKey:nil];
        } else {
            if ([_sectionIndexTitles count]) {
                NSInteger numberOfSections = [_sectionKeys count];
                
                [_sectionKeys removeAllObjects];
                [_sectionData removeAllObjects];
                [_sectionCounts removeAllObjects];
                [_sectionIndexTitles removeAllObjects];
                
                [_tableView deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(sectionKey, numberOfSections)] withRowAnimation:_rowAnimation];
            }
            
            [self setData:data forSectionWithKey:sectionKey];
        }
    } else if (labelKey) {
        if ([data count]) {
            NSString *sectionLabelSample = [data[0] valueForKey:labelKey];
            NSString *sectionInitial = [sectionLabelSample substringWithRange:NSMakeRange(0, 1)];
            
            [_sectionIndexTitles addObject:[sectionInitial uppercaseString]];
            
            NSMutableArray *sectionData = [NSMutableArray array];
            NSArray *remainingData = nil;
            
            for (NSInteger i = 0; !remainingData && i < [data count]; i++) {
                NSString *label = [data[i] valueForKey:labelKey];
                
                if ([[label lowercaseString] hasPrefix:[sectionInitial lowercaseString]]) {
                    [sectionData addObject:data[i]];
                } else {
                    remainingData = [data subarrayWithRange:NSMakeRange(i, [data count] - i)];
                }
            }
            
            [self setData:sectionData forSectionWithKey:sectionKey++];
            [self setData:remainingData sectionIndexLabelKey:nil];
        } else if ([_sectionKeys count] > sectionKey) {
            NSRange redundantSections = NSMakeRange(sectionKey, [_sectionKeys count] - sectionKey);
            NSArray *redundantSectionKeys = [_sectionKeys subarrayWithRange:redundantSections];
            
            [_sectionKeys removeObjectsInRange:redundantSections];
            [_sectionData removeObjectsForKeys:redundantSectionKeys];
            [_sectionCounts removeObjectsForKeys:redundantSectionKeys];
            
            [_tableView deleteSections:[NSIndexSet indexSetWithIndexesInRange:redundantSections] withRowAnimation:_rowAnimation];
        }
    }
}


- (id)dataAtIndexPath:(NSIndexPath *)indexPath
{
    return _sectionData[@([self sectionKeyForIndexPath:indexPath])][indexPath.row];
}


#pragma mark - View layout

- (BOOL)isBottomSectionKey:(NSInteger)sectionKey
{
    return sectionKey == [[_sectionKeys lastObject] integerValue];
}


- (BOOL)hasSectionWithKey:(NSInteger)sectionKey
{
    return [_sectionKeys containsObject:@(sectionKey)];
}


- (NSInteger)numberOfRowsInSectionWithKey:(NSInteger)sectionKey
{
    return [_sectionCounts[@(sectionKey)] integerValue];
}


- (NSInteger)sectionKeyForIndexPath:(NSIndexPath *)indexPath
{
    return [self sectionKeyForSectionNumber:indexPath.section];
}


#pragma mark - Communications

- (void)sendTextToRecipients:(id)recipients
{
    if (![recipients conformsToProtocol:@protocol(NSFastEnumeration)]) {
        recipients = @[recipients];
    }
    
    NSMutableArray *recipientNumbers = [NSMutableArray array];
    
    for (id<OMember> recipient in recipients) {
        [recipientNumbers addObject:recipient.mobilePhone];
    }
    
    MFMessageComposeViewController *messageComposer = [[MFMessageComposeViewController alloc] init];
    messageComposer.messageComposeDelegate = self;
    messageComposer.recipients = recipientNumbers;
    
    [self presentViewController:messageComposer animated:YES completion:nil];
}


- (void)sendEmailToRecipients:(id)toRecipients cc:(id)ccRecipients
{
    if (toRecipients && ![toRecipients conformsToProtocol:@protocol(NSFastEnumeration)]) {
        toRecipients = @[toRecipients];
    }
    
    if (ccRecipients && ![ccRecipients conformsToProtocol:@protocol(NSFastEnumeration)]) {
        ccRecipients = @[ccRecipients];
    }
    
    NSMutableArray *toAddresses = [NSMutableArray array];
    NSMutableArray *ccAddresses = [NSMutableArray array];
    
    for (id<OMember> toRecipient in toRecipients) {
        [toAddresses addObject:toRecipient.email];
    }
    
    for (id<OMember> ccRecipient in ccRecipients) {
        [ccAddresses addObject:ccRecipient.email];
    }
    
    MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
    mailComposer.mailComposeDelegate = self;
    [mailComposer setToRecipients:toAddresses];
    [mailComposer setCcRecipients:ccAddresses];
    [mailComposer setMessageBody:NSLocalizedString(@"Sent from Origo - http://origoapp.com", @"") isHTML:NO];
    
    [self presentViewController:mailComposer animated:YES completion:nil];
}


- (void)callRecipient:(id)recipient
{
    NSString *phoneNumber = nil;
    
    if ([recipient conformsToProtocol:@protocol(OMember)]) {
        phoneNumber = [OPhoneNumberFormatter formatterForNumber:[recipient mobilePhone]].flattenedNumber;
    } else if ([recipient conformsToProtocol:@protocol(OOrigo)]) {
        phoneNumber = [OPhoneNumberFormatter formatterForNumber:[recipient telephone]].flattenedNumber;
    }
    
    NSURL *phoneURL = [NSURL URLWithString:[kProtocolTel stringByAppendingString:phoneNumber]];
    
    if ([[UIApplication sharedApplication] canOpenURL:phoneURL]) {
        [[UIApplication sharedApplication] openURL:phoneURL];
    } else {
        [OAlert showAlertWithTitle:NSLocalizedString(@"Cannot place call", @"") text:[NSString stringWithFormat:NSLocalizedString(@"Please verify that %@ is a valid phone number.", @""), [OPhoneNumberFormatter formatterForNumber:phoneNumber].formattedNumber]];
    }
}


#pragma mark - Modal view controller handling

- (void)presentModalViewControllerWithIdentifier:(NSString *)identifier target:(id)target
{
    [self presentModalViewControllerWithIdentifier:identifier target:target meta:nil];
}


- (void)presentModalViewControllerWithIdentifier:(NSString *)identifier target:(id)target meta:(id)meta
{
    OTableViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
    
    viewController->_isModal = YES;
    viewController.target = target;
    
    if (viewController.entity && _entity) {
        viewController.entity.ancestor = _entity;
    }
    
    if ([meta isKindOfClass:[OTableViewController class]]) {
        viewController.dismisser = meta;
    } else {
        viewController.meta = meta;
        viewController.dismisser = self;
    }
    
    UIViewController *destinationViewController = nil;
    
    if ([identifier isEqualToString:kIdentifierAuth]) {
        destinationViewController = viewController;
    } else {
        destinationViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
    }
    
    [destinationViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    
    if (_presentStealthilyOnce) {
        if ([OMeta iOSVersionIs:@"7"]) {
            self.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
        } else {
            destinationViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
        }
        
        destinationViewController.view.alpha = 0.f;
        
        [self presentViewController:destinationViewController animated:NO completion:^{
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 1.f * NSEC_PER_SEC);
            dispatch_after(delay, dispatch_get_main_queue(), ^(void) {
                destinationViewController.view.alpha = 1.f;
            });
            
            if ([OMeta iOSVersionIs:@"7"]) {
                self.navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
            }
        }];
        
        _presentStealthilyOnce = NO;
    } else {
        [self.navigationController presentViewController:destinationViewController animated:YES completion:nil];
    }
}


- (void)dismissModalViewController:(OTableViewController *)viewController
{
    BOOL shouldRelayDismissal = NO;
    
    if (_isModal) {
        if ([_instance respondsToSelector:@selector(shouldRelayDismissalOfModalViewController:)]) {
            shouldRelayDismissal = [_instance shouldRelayDismissalOfModalViewController:viewController];
        }
    }
    
    if (shouldRelayDismissal) {
        _didCancel = viewController.didCancel;
        
        [_dismisser dismissModalViewController:self];
    } else {
        if ([viewController respondsToSelector:@selector(viewWillBeDismissed)]) {
            [viewController viewWillBeDismissed];
        }
        
        if ([_instance respondsToSelector:@selector(willDismissModalViewController:)]) {
            [_instance willDismissModalViewController:viewController];
        }
        
        if ([OMeta iOSVersionIs:@"8"] && viewController.presentedViewController) {
            // Dismissal of stacked modal view controllers does not work as documented in iOS 8.
            // Instead of animating the dismissal of the topmost view controller while simply
            // removing intermediate view controllers from the stack, all view controllers but
            // the one immediately on top of the dismissing view controller are removed from the
            // stack, thus making the latter suddenly appear and then be dismissed with an
            // animation.
            //
            // This workaround (more or less) emulates the intended behaviour by superimposing
            // a screenshot of the topmost view controller's view on top of the view of the view
            // controller whose dismissal is animated.
            
            UIView *snapshot = [[UIScreen mainScreen] snapshotViewAfterScreenUpdates:NO];
            [viewController.navigationController setNavigationBarHidden:YES animated:NO];
            [viewController.view addSubview:snapshot];
        }
        
        [self dismissViewControllerAnimated:YES completion:^{
            if ([[OMeta m] userIsLoggedIn] && !viewController.didCancel) {
                [self reloadSections];
            }
            
            if ([_instance respondsToSelector:@selector(didDismissModalViewController:)]) {
                [_instance didDismissModalViewController:viewController];
            }
        }];
    }
    
    [viewController.view endEditing:YES];
}


#pragma mark - Edit mode transitions

- (void)scrollToTopAndToggleEditMode
{
    if ([self actionIs:kActionDisplay]) {
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            [self toggleEditMode];
        }];
        
        [_tableView beginUpdates];
        [_tableView setContentOffset:CGPointMake(0.f, 0.f - _tableView.contentInset.top) animated:YES];
        [_tableView endUpdates];
        
        [CATransaction commit];
    } else {
        [self toggleEditMode];
    }
}


- (void)toggleEditMode
{
    [_inputCell toggleEditMode];
    
    if ([_instance respondsToSelector:@selector(didToggleEditMode)]) {
        [_instance didToggleEditMode];
    }
    
    static UIBarButtonItem *leftBarButtonItem = nil;
    static NSArray *rightBarButtonItems = nil;
    
    if ([self actionIs:kActionEdit]) {
        leftBarButtonItem = self.navigationItem.leftBarButtonItem;
        rightBarButtonItems = self.navigationItem.rightBarButtonItems;
        
        if (!_cancelButton) {
            _cancelButton = [UIBarButtonItem cancelButtonWithTarget:self];
            _nextButton = [UIBarButtonItem nextButtonWithTarget:self];
            _doneButton = [UIBarButtonItem doneButtonWithTarget:self];
        }
        
        self.navigationItem.leftBarButtonItem = _cancelButton;
        self.navigationItem.rightBarButtonItems = nil;
        
        if (_nextInputField) {
            [_nextInputField becomeFirstResponder];
            _nextInputField = nil;
        } else {
            [[_inputCell nextInputField] becomeFirstResponder];
        }
    } else if ([self actionIs:kActionDisplay]) {
        self.navigationItem.leftBarButtonItem = leftBarButtonItem;
        self.navigationItem.rightBarButtonItems = rightBarButtonItems;
        
        [[OMeta m].replicator replicateIfNeeded];
    }
    
    OLogState;
}


- (void)endEditing
{
    [self.view endEditing:YES];
    
    if ([self actionIs:kActionRegister]) {
        self.inputCell.editable = NO;
        self.navigationItem.rightBarButtonItems = @[_doneButton];
    }
}


#pragma mark - Inline editing

- (void)editInlineInCell:(OTableViewCell *)inlineCell
{
    _inlineCell = inlineCell;
    _inlineCell.selectable = NO;
    _inlineCellCancelRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelInlineEditingIfOngoing)];
    
    OInputField *inlineField = [_inlineCell inlineField];
    inlineField.editable = YES;
    [inlineField becomeFirstResponder];
    
    [self.view addGestureRecognizer:_inlineCellCancelRecogniser];
}


- (void)cancelInlineEditingIfOngoing
{
    if (_inlineCell && !_inlineCell.selectable) {
        _didCancel = YES;
        
        [self finishInlineEditing];
        
        _didCancel = NO;
    }
}


#pragma mark - Custom titles

- (UISegmentedControl *)titleSegmentsWithTitles:(NSArray *)segmentTitles
{
    if ([segmentTitles count]) {
        if (_titleSegments) {
            NSString *selectedTitle = [_titleSegments titleForSegmentAtIndex:_titleSegments.selectedSegmentIndex];
            
            if (![segmentTitles containsObject:selectedTitle]) {
                selectedTitle = nil;
            }
            
            _titleSegments.selectedSegmentIndex = UISegmentedControlNoSegment;
            
            for (NSInteger i = 0; i < [_titleSegmentTitles count]; i++) {
                NSString *segmentTitle = _titleSegmentTitles[i];
                
                if (![segmentTitles containsObject:segmentTitle]) {
                    [_titleSegments removeSegmentAtIndex:i animated:YES];
                    [_titleSegmentTitles removeObjectAtIndex:i];
                }
            }
            
            for (NSInteger i = 0; i < [segmentTitles count]; i++) {
                NSString *segmentTitle = segmentTitles[i];
                
                if (![_titleSegmentTitles containsObject:segmentTitle]) {
                    [_titleSegments insertSegmentWithTitle:segmentTitle atIndex:i animated:YES];
                    [_titleSegmentTitles insertObject:segmentTitle atIndex:i];
                }
                
                if (selectedTitle && [segmentTitle isEqualToString:selectedTitle]) {
                    _titleSegments.selectedSegmentIndex = i;
                }
            }
            
            if (_titleSegments.selectedSegmentIndex < 0) {
                _titleSegments.selectedSegmentIndex = 0;
            }
        } else {
            _titleSegmentTitles = [segmentTitles mutableCopy];
            _titleSegments = [[UISegmentedControl alloc] initWithItems:segmentTitles];
            _titleSegments.selectedSegmentIndex = 0;
            _titleSegments.frame = CGRectMake(kContentInset, kContentInset / 2.f, [OMeta screenWidth] - 2 * kContentInset, _titleSegments.frame.size.height);
            [_titleSegments addTarget:_instance action:@selector(didSelectTitleSegment) forControlEvents:UIControlEventValueChanged];
            
            UIView *segmentsHairline = [[UIView alloc] initWithFrame:CGRectMake(0.f, kToolbarBarHeight, [OMeta screenWidth], kBorderWidth)];
            segmentsHairline.backgroundColor = [UIColor toolbarHairlineColour];
            
            UIView *segmentsView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, [OMeta screenWidth], kToolbarBarHeight)];
            segmentsView.backgroundColor = [UIColor toolbarColour];
            
            [segmentsView addSubview:_titleSegments];
            [segmentsView addSubview:segmentsHairline];
            [self.view addSubview:segmentsView];
            
            if (_tableView) {
                [_tableView setTopContentInset:_tableView.contentInset.top + kToolbarBarHeight];
            }
        }
    } else if (_titleSegments) {
        [_titleSegments.superview removeFromSuperview];
        _titleSegments = nil;
        
        [_tableView setTopContentInset:_tableView.contentInset.top - kToolbarBarHeight];
    }
    
    return _titleSegments;
}


#pragma mark - Reloading sections

- (void)reloadSections
{
    UITableViewRowAnimation rowAnimation = [self rowAnimation];
    
    if (_needsReloadInputSection) {
        [_tableView reloadSections:[NSIndexSet indexSetWithIndex:[self sectionNumberForSectionKey:_inputSectionKey]] withRowAnimation:rowAnimation];
        
        _needsReloadInputSection = NO;
    }
    
    [_tableView beginUpdates];
    [_instance loadData];
    
    NSArray *sectionKeys = [[_sectionData allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSMutableIndexSet *sectionsToReload = [NSMutableIndexSet indexSet];
    NSMutableIndexSet *sectionsToInsert = [NSMutableIndexSet indexSet];
    NSMutableIndexSet *sectionsToDelete = [NSMutableIndexSet indexSet];
    
    for (NSNumber *sectionKey in sectionKeys) {
        if ([self isEntityViewController] && [sectionKey integerValue] == _inputSectionKey) {
            if (![self actionIs:kActionInput]) {
                [_inputCell readData];
            }
        } else {
            NSInteger section = [self sectionNumberForSectionKey:[sectionKey integerValue]];
            
            if (section != NSNotFound) {
                NSInteger oldCount = [_sectionCounts[sectionKey] integerValue];
                NSInteger newCount = [_sectionData[sectionKey] count];
                
                if (oldCount) {
                    if (newCount) {
                        [sectionsToReload addIndex:section - [sectionsToInsert count]];
                    } else {
                        [sectionsToDelete addIndex:section - [sectionsToInsert count]];
                    }
                } else if (newCount) {
                    [sectionsToInsert addIndex:section];
                }
                
                _sectionCounts[sectionKey] = @(newCount);
            }
        }
    }
    
    if ([sectionsToReload count]) {
        [_tableView reloadSections:sectionsToReload withRowAnimation:rowAnimation];
    }
    
    if ([sectionsToInsert count]) {
        [_tableView insertSections:sectionsToInsert withRowAnimation:rowAnimation];
    }
    
    if ([sectionsToDelete count]) {
        [_tableView deleteSections:sectionsToDelete withRowAnimation:rowAnimation];
        
        NSInteger deletedSection = [sectionsToDelete firstIndex];
        
        while (deletedSection != NSNotFound) {
            [_sectionKeys removeObject:@([self sectionKeyForSectionNumber:deletedSection])];
            deletedSection = [sectionsToDelete indexGreaterThanIndex:deletedSection];
        }
    }
    
    if ([_sectionKeys count]) {
        NSMutableIndexSet *affectedSections = [NSMutableIndexSet indexSet];
        [affectedSections addIndexes:sectionsToReload];
        [affectedSections addIndexes:sectionsToInsert];
        [affectedSections addIndexes:sectionsToDelete];
        
        NSInteger topmostAffectedSection = [affectedSections firstIndex];
        NSInteger bottomAffectedSection = [affectedSections lastIndex];
        NSInteger bottomSection = [self sectionNumberForSectionKey:[[_sectionKeys lastObject] integerValue]];
        
        if (topmostAffectedSection != NSNotFound) {
            if (topmostAffectedSection > 0) {
                [self reloadFooterForSection:topmostAffectedSection - 1];
            }
            
            if (bottomAffectedSection < bottomSection) {
                [self reloadHeaderForSection:bottomAffectedSection + 1];
            }
        }
    }
    
    [self setTableViewFooterViewIfNeeded];
    
    [_tableView endUpdates];
}


- (void)reloadSectionWithKey:(NSInteger)sectionKey
{
    [self reloadSectionWithKey:sectionKey rowAnimation:[self rowAnimation]];
}


- (void)reloadSectionWithKey:(NSInteger)sectionKey rowAnimation:(UITableViewRowAnimation)rowAnimation
{
    if ([self isEntityViewController] && sectionKey == _inputSectionKey) {
        _needsReloadInputSection = YES;
    } else {
        [_instance loadData];
        
        BOOL sectionExists = [_sectionCounts[@(sectionKey)] integerValue] > 0;
        BOOL sectionIsEmpty = ![_sectionData[@(sectionKey)] count];
        
        [_tableView beginUpdates];
        
        if (sectionExists || !sectionIsEmpty) {
            _sectionCounts[@(sectionKey)] = @([_sectionData[@(sectionKey)] count]);
            
            NSInteger section = [self sectionNumberForSectionKey:sectionKey];
            NSInteger bottomSection = [self sectionNumberForSectionKey:[[_sectionKeys lastObject] integerValue]];
            
            if (section == 0 && section < bottomSection) {
                [self reloadHeaderForSection:section + 1];
            } else if (section < bottomSection) {
                [self reloadFooterForSection:section - 1];
                [self reloadHeaderForSection:section + 1];
            } else if (section > 0) {
                [self reloadFooterForSection:section - 1];
            }
            
            if (sectionExists && !sectionIsEmpty) {
                [_tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:rowAnimation];
            } else if (!sectionExists && !sectionIsEmpty) {
                [_tableView insertSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:rowAnimation];
            } else if (sectionExists && sectionIsEmpty) {
                [_sectionKeys removeObject:@(sectionKey)];
                [_tableView deleteSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:rowAnimation];
            }
        }
        
        [self setTableViewFooterViewIfNeeded];
        
        [_tableView endUpdates];
    }
}


#pragma mark - Reloading headers & footers

- (void)reloadHeaderForSectionWithKey:(NSInteger)sectionKey
{
    BOOL hasHeader = NO;
    
    if ([_instance respondsToSelector:@selector(hasHeaderForSectionWithKey:)]) {
        hasHeader = [_instance hasHeaderForSectionWithKey:sectionKey];
    } else {
        hasHeader = [self sectionNumberForSectionKey:sectionKey] > 0;
    }
    
    if (hasHeader) {
        id headerContent = [_instance headerContentForSectionWithKey:sectionKey];
        
        if ([headerContent isKindOfClass:[NSString class]]) {
            [_sectionHeaderLabels[@(sectionKey)] setText:headerContent];
        }
    } else if ([_sectionHeaderLabels[@(sectionKey)] text]) {
        [_sectionHeaderLabels[@(sectionKey)] setText:nil];
    }
}


- (void)reloadFooterForSectionWtihKey:(NSInteger)sectionKey
{
    BOOL hasFooter = NO;
    
    if ([_instance respondsToSelector:@selector(hasFooterForSectionWithKey:)]) {
        hasFooter = [_instance hasFooterForSectionWithKey:sectionKey];
    }
    
    if (hasFooter) {
        id footerContent = [_instance footerContentForSectionWithKey:sectionKey];
        
        if ([footerContent isKindOfClass:[NSString class]]) {
            [_sectionFooterLabels[@(sectionKey)] setText:footerContent];
        }
    } else if ([_sectionFooterLabels[@(sectionKey)] text]) {
        [_sectionFooterLabels[@(sectionKey)] setText:nil];
    }
}


#pragma mark - View lifecycle

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:[OMeta m].appDelegate.window.bounds];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _identifier = self.restorationIdentifier;
    _usesTableView = YES;
    _sectionKeys = [NSMutableArray array];
    _sectionData = [NSMutableDictionary dictionary];
    _sectionCounts = [NSMutableDictionary dictionary];
    _sectionHeaderLabels = [NSMutableDictionary dictionary];
    _sectionFooterLabels = [NSMutableDictionary dictionary];
    _inputSectionKey = NSNotFound;
    _instance = self;
    _state = [[OState alloc] initWithViewController:self];
    _rowAnimation = UITableViewRowAnimationNone;
    
    [self initialiseInstance];
    
    if (self.title && !self.navigationItem.backBarButtonItem) {
        CGFloat titleWidth = [self.title sizeWithFont:[UIFont navigationBarTitleFont] maxWidth:CGFLOAT_MAX].width;
        
        if (titleWidth / [OMeta screenWidth] > 0.3f) {
            self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:NSLocalizedString(@"Back", @"")];
        }
    }
    
    if (_usesTableView) {
        CGRect tableViewFrame = self.view.frame;
        tableViewFrame.size.height -= self.navigationController ? kNavigationBarHeight : 0.f;
        
        if (_usesPlainTableViewStyle) {
            _tableView = [[OTableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain];
            _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        } else {
            _tableView = [[OTableView alloc] initWithFrame:tableViewFrame style:UITableViewStyleGrouped];
        }
        
        _tableView.dataSource = self;
        _tableView.delegate = self;
        
        if (_titleSegments) {
            [self.view insertSubview:_tableView belowSubview:_titleSegments.superview];
            
            [_tableView setTopContentInset:_tableView.contentInset.top + kToolbarBarHeight];
        } else {
            [self.view addSubview:_tableView];
        }
        
        if ([self actionIs:kActionRegister]) {
            _nextButton = [UIBarButtonItem nextButtonWithTarget:self];
            _doneButton = [UIBarButtonItem doneButtonWithTarget:self];
            
            if (_isModal) {
                if ([[OMeta m].user isActive]) {
                    if (_cancelImpliesSkip) {
                        self.navigationItem.leftBarButtonItem = [UIBarButtonItem skipButtonWithTarget:self];
                    } else {
                        self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
                    }
                } else {
                    self.navigationItem.leftBarButtonItem = [UIBarButtonItem logoutButtonWithTarget:[OMeta m]];
                }
            }
            
            [self.navigationItem insertRightBarButtonItem:_nextButton atIndex:0];
        }
        
        if ([_instance respondsToSelector:@selector(supportsPullToRefresh)]) {
            if ([_instance supportsPullToRefresh]) {
                _refreshControl = [[UIRefreshControl alloc] init];
                _refreshControl.tintColor = [UIColor lightGrayColor];
                [_refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
                
                [_tableView insertSubview:_refreshControl atIndex:0];
            }
        }
    }
    
    _didJustLoad = YES;
}


- (void)viewWillAppear:(BOOL)animated
{
    if (!_didInitialise && self.target) {
        [self initialiseInstance];
    }
    
    [super viewWillAppear:animated];
    
    _wasHidden = _isHidden;
    _isHidden = NO;
    _isPushed = [self isMovingToParentViewController] || (_didJustLoad && !_isModal);
    _didResurface = !_isPushed && !_wasHidden && (!_isModal || !_didJustLoad);
    _didJustLoad = NO;
    
    [_state makeActive];

    [self setToolbarItemsIfApplicable];
    
    if (self.navigationController.navigationBar.translucent) {
        self.navigationController.navigationBar.translucent = NO;
        self.navigationController.navigationBar.barTintColor = [UIColor toolbarColour];
    }
    
    if ([[OMeta m] userIsAllSet]) {
        [self.navigationController.navigationBar setHairlinesHidden:_titleSegments != nil];
        
        if (_isUsingSectionIndexTitles) {
            _tableView.sectionIndexMinimumDisplayRowCount = kSectionIndexMinimumDisplayRowCount;
        }
        
        [self setTableViewFooterViewIfNeeded];
        
        if (_didResurface) {
            [self reloadSections];
        }
        
        if (_didResurface && [self actionIs:kActionInput]) {
            [self.inputCell resumeFirstResponder];
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    OLogState;
    
    if ([[OMeta m] userIsLoggedIn]) {
        if (_inputCell && !_didResurface && !_isHidden) {
            [_inputCell prepareForInput];
            
            if ([self actionIs:kActionRegister] && !_wasHidden) {
                if (![_inputCell nextInvalidInputField]) {
                    [[_inputCell nextInputField] becomeFirstResponder];
                }
            }
        }
        
        if (_titleView && _shouldBeginEditingTitleView) {
            _titleView.editing = YES;
            _shouldBeginEditingTitleView = NO;
        }
        
        if (_didResurface) {
            [_tableView setBottomContentInset:self.toolbarItems ? kToolbarBarHeight : 0.f];
        }
    } else if (![_identifier isEqualToString:kIdentifierAuth]) {
        [self presentModalViewControllerWithIdentifier:kIdentifierAuth target:kTargetUser];
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    _isHidden = self.presentedViewController ? YES : NO;
    _wasHidden = NO;
    
    [[OMeta m].replicator replicateIfNeeded];
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (_needsReinstantiateRootViewController) {
        self.navigationController.viewControllers = @[_reinstantiatedRootViewController];
        _needsReinstantiateRootViewController = NO;
    }
}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - Custom accessors

- (void)setTarget:(id)target
{
    if (target) {
        _target = target;
        
        id ancestor = _entity.ancestor;
        
        if ([target conformsToProtocol:@protocol(OEntity)]) {
            _entity = [target proxy];
        } else if ([self isEntityViewController]) {
            _entity = [[_entityClass proxyClass] proxyForEntityOfClass:_entityClass meta:target];
        }
        
        if (_entity) {
            _target = _entity;
            _entity.ancestor = ancestor;
            
            if ([self respondsToSelector:@selector(didSetEntity:)]) {
                [self didSetEntity:_entity];
            }
        }
        
        if (_state) {
            _state.target = target;
        }
    }
}


- (id)target
{
    if (!_target && [[OMeta m] userIsLoggedIn]) {
        self.target = [OMeta m].user;
    }
    
    return _state && [_target isKindOfClass:[NSDictionary class]] ? [_target allKeys][0] : _target;
}


- (void)setUsesSectionIndexTitles:(BOOL)usesSectionIndexTitles
{
    _usesSectionIndexTitles = usesSectionIndexTitles;
    
    if (_usesSectionIndexTitles) {
        _usesPlainTableViewStyle = YES;
    }
}


- (UITableViewRowAnimation)rowAnimation
{
    UITableViewRowAnimation rowAnimation = UITableViewRowAnimationFade;
    
    if (_rowAnimation != UITableViewRowAnimationNone) {
        rowAnimation = _rowAnimation;
        _rowAnimation = UITableViewRowAnimationNone;
    }
    
    return rowAnimation;
}


- (void)setTitleView:(OTitleView *)titleView
{
    _titleView = titleView;
    _titleView.delegate = self;
    _shouldBeginEditingTitleView = ![titleView.title hasValue];
    
    self.navigationItem.titleView = _titleView;
    self.title = _titleView.title;
}


#pragma mark - UIViewController overrides

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    
    if (_titleView) {
        _titleView.title = title;
    }
}


#pragma mark - OTableViewController conformance

- (void)loadState
{
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}


- (void)loadData
{
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}


- (void)didLogout
{
    _needsReinstantiateRootViewController = YES;
    _reinstantiatedRootViewController = [self.storyboard instantiateViewControllerWithIdentifier:kIdentifierOrigoList];
    
    [self presentModalViewControllerWithIdentifier:kIdentifierAuth target:kTargetUser meta:_reinstantiatedRootViewController];
}


#pragma mark - OConnectionDelegate conformance

- (void)connection:(OConnection *)connection willSendRequest:(NSURLRequest *)request
{
    if (_requiresSynchronousServerCalls) {
        [[OMeta m].activityIndicator startAnimating];
    }
}


- (void)connection:(OConnection *)connection didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    if ([OMeta m].activityIndicator.isAnimating) {
        [[OMeta m].activityIndicator stopAnimating];
    }
}


- (void)connection:(OConnection *)connection didFailWithError:(NSError *)error
{
    if ([OMeta m].activityIndicator.isAnimating) {
        [[OMeta m].activityIndicator stopAnimating];
    }
    
    // TODO: Handle errors (-1001: Timeout, and others)
}


#pragma mark - OTitleViewDelegate conformance

- (BOOL)shouldBeginEditingTitleView:(OTitleView *)titleView
{
    BOOL shouldBeginEditing = _shouldBeginEditingTitleView;
    
    if (shouldBeginEditing) {
        _shouldBeginEditingTitleView = NO;
    } else {
        NSString *buttonTitle = [NSLocalizedString(@"Edit", @"") stringByAppendingString:[_titleView.placeholder stringByConditionallyLowercasingFirstLetter] separator:kSeparatorSpace];
        
        [OActionSheet singleButtonActionSheetWithButtonTitle:buttonTitle action:^{
            _titleView.editing = YES;
        }];
    }
    
    return shouldBeginEditing;
}


- (void)didBeginEditingTitleView:(OTitleView *)titleView
{
    [self setEditingTitle:YES];
}


- (BOOL)shouldFinishEditingTitleView:(OTitleView *)titleView
{
    return [titleView.titleField.text hasValue];
}


- (void)didFinishEditingTitleView:(OTitleView *)titleView
{
    [self setEditingTitle:NO];
}


#pragma mark - UITableViewDataSource conformance

- (NSInteger)numberOfSectionsInTableView:(OTableView *)tableView
{
    return [_sectionKeys count];
}


- (NSInteger)tableView:(OTableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_sectionCounts[@([_sectionKeys[section] integerValue])] integerValue];
}


- (CGFloat)tableView:(OTableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = kDefaultCellHeight;
    
    if (indexPath.section == [self sectionNumberForSectionKey:_inputSectionKey]) {
        if (_inputCell) {
            height = [_inputCell.constrainer heightOfInputCell];
        } else {
            height = [OInputCellConstrainer heightOfInputCellWithEntity:_entity delegate:_instance];
        }
    }
    
    return height;
}


- (UITableViewCell *)tableView:(OTableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTableViewCell *cell = nil;
    
    if (indexPath.section == [self sectionNumberForSectionKey:_inputSectionKey]) {
        NSString *reuseIdentifier = nil;
        
        if ([_instance respondsToSelector:@selector(reuseIdentifierForInputSection)]) {
            reuseIdentifier = [_instance reuseIdentifierForInputSection];
        }
        
        if (reuseIdentifier) {
            cell = [tableView inputCellWithReuseIdentifier:reuseIdentifier delegate:_instance];
        } else {
            cell = [tableView inputCellWithEntity:_entity delegate:_instance];
        }
        
        _inputCell = cell;
    } else {
        UITableViewCellStyle style = kTableViewCellStyleDefault;
        
        if ([_instance respondsToSelector:@selector(listCellStyleForSectionWithKey:)]) {
            style = [_instance listCellStyleForSectionWithKey:[self sectionKeyForIndexPath:indexPath]];
        }
        
        cell = [tableView listCellWithStyle:style data:[self dataAtIndexPath:indexPath] delegate:_instance];
    }
    
    return cell;
}


- (BOOL)tableView:(OTableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDeleteCell = NO;
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey != _inputSectionKey && ![OMeta m].replicator.isReplicating) {
        if ([_instance respondsToSelector:@selector(canDeleteCellAtIndexPath:)]) {
            canDeleteCell = [_instance canDeleteCellAtIndexPath:indexPath];
        }
    }
    
    return canDeleteCell;
}


- (NSString *)tableView:(OTableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *buttonTitle = nil;
    
    if ([_instance respondsToSelector:@selector(deleteConfirmationButtonTitleForCellAtIndexPath:)]) {
        buttonTitle = [_instance deleteConfirmationButtonTitleForCellAtIndexPath:indexPath];
    }
    
    return buttonTitle ? buttonTitle : NSLocalizedString(@"Delete", @"");
}


- (void)tableView:(OTableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        BOOL shouldDeleteCell = YES;
        
        if ([_instance respondsToSelector:@selector(shouldDeleteCellAtIndexPath:)]) {
            shouldDeleteCell = [_instance shouldDeleteCellAtIndexPath:indexPath];
        }
        
        if (shouldDeleteCell) {
            if ([_instance respondsToSelector:@selector(deleteCellAtIndexPath:)]) {
                [_instance deleteCellAtIndexPath:indexPath];
            }
            
            NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
            
            if ([self numberOfRowsInSectionWithKey:sectionKey] == 1) {
                [self reloadSections];
            } else {
                [self reloadSectionWithKey:sectionKey];
            }
            
            [[OMeta m].replicator replicateIfNeeded];
        }
    }
}


- (NSArray *)sectionIndexTitlesForTableView:(OTableView *)tableView
{
    return _sectionIndexTitles;
}


- (NSInteger)tableView:(OTableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return index;
}


#pragma mark - UITableViewDelegate conformance

- (CGFloat)tableView:(OTableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = 0.f;
    
    if (_usesPlainTableViewStyle) {
        height = [_sectionIndexTitles count] ? kPlainTableViewHeaderHeight : 0.f;
    } else if ([self shouldEliminateSpaceAboveSection:section]) {
        height = kEliminatedHeaderFooterHeight;
    } else {
        NSInteger sectionKey = [self sectionKeyForSectionNumber:section];
        
        if ([self instanceHasHeaderForSectionWithKey:sectionKey]) {
            if ([_instance respondsToSelector:@selector(headerHeightForSectionWithKey:)]) {
                height = [_instance headerHeightForSectionWithKey:sectionKey];
            }
            
            if (!height) {
                if (_usesPlainTableViewStyle) {
                    height = [UIFont plainHeaderFont].lineHeight;
                } else {
                    CGFloat headroom = section > 0 ? 0.f : kInitialHeadroomHeight / 2.f;
                    
                    height = [[UIFont headerFont] headerHeight] + headroom;
                }
            }
        } else if (section == 0) {
            height = kInitialHeadroomHeight;
        } else {
            height = kEmptyHeaderHeight;
        }
    }
    
    return height;
}


- (CGFloat)tableView:(OTableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGFloat height = _usesPlainTableViewStyle ? 0.f : kEmptyFooterHeight;
    
    if ([self shouldEliminateSpaceBelowSection:section]) {
        height = kEliminatedHeaderFooterHeight;
    } else {
        NSInteger sectionKey = [self sectionKeyForSectionNumber:section];
        
        if ([self instanceHasFooterForSectionWithKey:sectionKey]) {
            if ([_instance respondsToSelector:@selector(footerHeightForSectionWithKey:)]) {
                height = [_instance footerHeightForSectionWithKey:sectionKey];
            }
            
            if (!height || height == kEmptyFooterHeight) {
                height = [self footerHeightWithText:[self footerForSectionWithKey:sectionKey]];
            }
        }
    }
    
    return height;
}


- (UIView *)tableView:(OTableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSInteger sectionKey = [self sectionKeyForSectionNumber:section];
    UIView *headerView = nil;
    id headerContent = nil;
    
    if (_isUsingSectionIndexTitles) {
        headerContent = _sectionIndexTitles[section];
    } else if ([self instanceHasHeaderForSectionWithKey:sectionKey]) {
        headerContent = [_instance headerContentForSectionWithKey:sectionKey];
    }
    
    if ([headerContent isKindOfClass:[NSArray class]] && [headerContent count] == 1) {
        headerContent = headerContent[0];
    }
    
    if ([headerContent isKindOfClass:[NSString class]]) {
        CGFloat headerViewHeight = [self tableView:tableView heightForHeaderInSection:section];
        CGFloat headerHeight = [[UIFont headerFont] headerHeight];
        CGFloat headroom = headerViewHeight - headerHeight;
        CGRect headerViewFrame = CGRectMake(0.f, 0.f, [OMeta screenWidth], headerViewHeight);
        headerView = [[UIView alloc] initWithFrame:headerViewFrame];
        
        CGRect headerFrame = CGRectMake(kContentInset, headroom, [OMeta screenWidth] - 2 * kContentInset, headerHeight);
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:headerFrame];
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.textColor = [UIColor headerTextColour];
        
        if (_usesPlainTableViewStyle) {
            headerView.backgroundColor = [UIColor tableViewBackgroundColour];
            headerView.alpha = 0.99f;
            headerLabel.font = [UIFont listTextFont];
        } else {
            headerLabel.font = [UIFont headerFont];
        }
        
        headerLabel.text = headerContent;
        headerLabel.textAlignment = NSTextAlignmentLeft;
        [headerView addSubview:headerLabel];
        
        [_sectionHeaderLabels setObject:headerLabel forKey:@(sectionKey)];
    } else if ([headerContent isKindOfClass:[NSArray class]]) {
        headerView = [self segmentedHeaderViewWithSegmentTitles:headerContent inSection:section];
        
        _segmentedHeaderSectionKey = sectionKey;
    } else if ([headerContent isKindOfClass:[UIView class]]) {
        headerView = headerContent;
    }
    
    return headerView;
}


- (UIView *)tableView:(OTableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSInteger sectionKey = [self sectionKeyForSectionNumber:section];
    UIView *footerView = nil;
    
    if ([self instanceHasFooterForSectionWithKey:sectionKey]) {
        id footer = [self footerForSectionWithKey:sectionKey];
        
        if ([footer isKindOfClass:[NSString class]]) {
            footerView = [self footerViewWithText:footer];
            
            [_sectionFooterLabels setObject:footerView.subviews[0] forKey:@(sectionKey)];
        } else if ([footer isKindOfClass:[UIView class]]) {
            footerView = footer;
        }
    }
    
    return footerView;
}


- (void)tableView:(OTableView *)tableView willDisplayCell:(OTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (cell == _inputCell) {
        [_inputCell prepareForDisplay];
        
        if ([_instance respondsToSelector:@selector(willDisplayInputCell:)]) {
            [_instance willDisplayInputCell:cell];
        }
    } else {
        [_instance loadListCell:cell atIndexPath:indexPath];
    }
}


- (void)tableView:(OTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTableViewCell *cell = (OTableViewCell *)[_tableView cellForRowAtIndexPath:indexPath];
    
    BOOL didSelectCell = cell.selectable;
    
    if (cell.destinationId) {
        if (![self actionIs:kActionInput] || cell.selectableDuringInput) {
            id target = cell.destinationTarget ? cell.destinationTarget : [self dataAtIndexPath:indexPath];
            
            OTableViewController *destinationViewController = [self.storyboard instantiateViewControllerWithIdentifier:cell.destinationId];
            destinationViewController.target = target;
            destinationViewController.meta = cell.destinationMeta;
            
            if (destinationViewController.entity && _entity) {
                destinationViewController.entity.ancestor = _entity;
            }
            
            [self.navigationController pushViewController:destinationViewController animated:YES];
        } else {
            cell.selected = NO;
            didSelectCell = NO;
        }
    }
    
    if (didSelectCell) {
        if ([_instance respondsToSelector:@selector(didSelectCell:atIndexPath:)]) {
            [_instance didSelectCell:cell atIndexPath:indexPath];
        }
        
        _selectedIndexPath = indexPath;
    }
}


#pragma mark - UITextFieldDelegate conformance

- (void)textFieldDidBeginEditing:(OTextField *)textField
{
    if ([_inputCell hasInputField:textField]) {
        [self inputFieldDidBecomeFirstResponder:textField];
    }
}


- (BOOL)textFieldShouldReturn:(OTextField *)textField
{
    if ([_inputCell hasInputField:textField]) {
        if ([_inputCell nextInputField]) {
            [self moveToNextInputField];
        } else {
            [self didFinishEditing];
        }
    } else if (textField.isInlineField) {
        if ([textField hasValidValue]) {
            [self finishInlineEditing];
        }
    }
    
    return NO;
}


- (void)textFieldDidEndEditing:(OTextField *)textField
{
    if ([_inputCell hasInputField:textField]) {
        _inputCell.inputField = nil;
    }
}


#pragma mark - UITextViewDelegate conformance

- (void)textViewDidBeginEditing:(OTextView *)textView
{
    [self inputFieldDidBecomeFirstResponder:textView];
}


- (void)textViewDidChange:(OTextView *)textView
{
    [_inputCell redrawIfNeeded];
}


- (void)textViewDidEndEditing:(OTextView *)textView
{
    _inputCell.inputField = nil;
}


#pragma mark - MFMessageComposeViewControllerDelegate conformance

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    if ([self isModal] && result != MessageComposeResultCancelled) {
        [self.dismisser dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


#pragma mark - MFMailComposeViewControllerDelegate conformance

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if ([self isModal] && result != MFMailComposeResultCancelled) {
        [self.dismisser dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
