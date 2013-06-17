//
//  OLocator.m
//  OrigoApp
//
//  Created by Anders Blehr on 29.04.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OLocator.h"

#import "OMeta.h"
#import "OSettings.h"
#import "OState.h"
#import "OStrings.h"
#import "OUtil.h"

#import "OMember+OrigoExtensions.h"
#import "OMembership.h"
#import "OOrigo.h"

#import "OLocatorDelegate.h"


@implementation OLocator

#pragma mark - Auxiliary methods

- (void)showBlockingAlert
{
    _blockingAlert = [[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTextLocating] message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    
    [_blockingAlert show];
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicator.center = CGPointMake(_blockingAlert.bounds.size.width / 2.f, _blockingAlert.bounds.size.height - 50.f);
    
    [_blockingAlert addSubview:activityIndicator];
    
    [activityIndicator startAnimating];
}


#pragma mark - Initialisation

- (id)init
{
    self = [super init];
    
    if (self && [self canLocate]) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    
    return self;
}


#pragma mark - Location status

- (BOOL)isAuthorised
{
    BOOL canLocate = NO;
    
    if ([CLLocationManager locationServicesEnabled]) {
        canLocate = ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized);
    }
    
    return canLocate;
}


- (BOOL)canLocate
{
    BOOL canLocate = [self isAuthorised];
    
    if (!canLocate && [CLLocationManager locationServicesEnabled]) {
        canLocate = ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined);
    }
    
    return canLocate;
}


- (BOOL)didLocate
{
    return (_placemark != nil);
}


#pragma mark - Locating

- (void)locateBlocking:(BOOL)blocking
{
    if ([self canLocate]) {
        if ([self isAuthorised]) {
            if (_blocking) {
                [self showBlockingAlert];
            }
        } else {
            _awaitingAuthorisation = YES;
        }
        
        _blocking = blocking;
        _awaitingLocation = YES;
        _delegate = (id<OLocatorDelegate>)[OState s].viewController;
        
        [_locationManager startUpdatingLocation];
    }
}


#pragma mark - Custom property accessors

- (NSString *)countryCode
{
    return _placemark ? _placemark.ISOcountryCode : nil;
}


#pragma mark - CLLocationManagerDelegate conformance

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    [manager stopUpdatingLocation];
    
    if (_awaitingLocation) {
        if (_blocking) {
            [_blockingAlert dismissWithClickedButtonIndex:0 animated:YES];
        }
        
        [[[CLGeocoder alloc] init] reverseGeocodeLocation:manager.location completionHandler:^(NSArray *placemarks, NSError *error) {
            _placemark = placemarks[0];
            
            [_delegate locatorDidLocate];
        }];
        
        _awaitingLocation = NO;
    }
}


- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (_awaitingAuthorisation) {
        if (status == kCLAuthorizationStatusAuthorized) {
            if (_blocking) {
                [self showBlockingAlert];
            }
        } else if (status == kCLAuthorizationStatusDenied) {
            [_delegate locatorCannotLocate];
            
            _awaitingLocation = NO;
        }
        
        _awaitingAuthorisation = NO;
    }
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if (_awaitingLocation) {
        if (_blocking) {
            [_blockingAlert dismissWithClickedButtonIndex:0 animated:YES];
        }
        
        if (error.code != kCLErrorLocationUnknown) {
            [_delegate locatorCannotLocate];
        }
        
        _awaitingLocation = NO;
    }
}

@end
