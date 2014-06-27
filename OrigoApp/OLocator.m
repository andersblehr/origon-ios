//
//  OLocator.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OLocator.h"


@interface OLocator () <CLLocationManagerDelegate, UIAlertViewDelegate> {
@private
    CLLocationManager *_locationManager;
    CLPlacemark *_placemark;
    
    BOOL _awaitingAuthorisation;
    BOOL _awaitingLocation;
    
    id<OLocatorDelegate> _delegate;
}

@end


@implementation OLocator

#pragma mark - Initialisation

- (instancetype)init
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
        canLocate = [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized;
    }
    
    return canLocate;
}


- (BOOL)canLocate
{
    BOOL canLocate = [self isAuthorised];
    
    if (!canLocate && [CLLocationManager locationServicesEnabled]) {
        canLocate = [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined;
    }
    
    return canLocate;
}


- (BOOL)didLocate
{
    return _placemark ? YES : NO;
}


#pragma mark - Locating

- (void)locateBlocking:(BOOL)blocking
{
    if ([self canLocate]) {
        _blocking = blocking;
        
        if ([self isAuthorised]) {
            if (_blocking) {
                [[OMeta m].activityIndicator startAnimating];
            }
        } else {
            _awaitingAuthorisation = YES;
        }
        
        _awaitingLocation = YES;
        _delegate = (id<OLocatorDelegate>)[OState s].viewController;
        
        [_locationManager startUpdatingLocation];
    }
}


#pragma mark - Custom property accessors

- (NSString *)countryCode
{
    return _placemark ? [_placemark.ISOcountryCode lowercaseString] : nil;
}


#pragma mark - CLLocationManagerDelegate conformance

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    [manager stopUpdatingLocation];
    
    if (_awaitingLocation) {
        if (_blocking) {
            [[OMeta m].activityIndicator stopAnimating];
        }
        
        [[[CLGeocoder alloc] init] reverseGeocodeLocation:manager.location completionHandler:^(NSArray *placemarks, NSError *error) {
            _placemark = placemarks[0];
            
            [_delegate locatorDidLocate];
        }];
        
        _blocking = NO;
        _awaitingLocation = NO;
    }
}


- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (_awaitingAuthorisation) {
        if (status == kCLAuthorizationStatusAuthorized) {
            if (_blocking) {
                [[OMeta m].activityIndicator startAnimating];
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
        if ((error.code != kCLErrorLocationUnknown) || [OMeta deviceIsSimulator]) {
            if (_blocking) {
                [[OMeta m].activityIndicator stopAnimating];
            }
            
            [_delegate locatorCannotLocate];
            
            _blocking = NO;
            _awaitingLocation = NO;
        }
    }
}

@end
