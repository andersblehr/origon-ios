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


#pragma mark - Updating location info

- (BOOL)canLocate
{
    BOOL canLocate = [self canLocateSilently];
    
    if (!canLocate && [CLLocationManager locationServicesEnabled]) {
        canLocate = ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined);
    }
    
    return canLocate;
}


- (BOOL)canLocateSilently
{
    BOOL canLocate = NO;
    
    if ([CLLocationManager locationServicesEnabled]) {
        canLocate = ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized);
    }
    
    return canLocate;
}


- (BOOL)didLocate
{
    return (_placemark != nil);
}


- (void)locate
{
    if ([self canLocate]) {
        _delegate = (id<OLocatorDelegate>)[OState s].viewController;
        
        [_locationManager startUpdatingLocation];
    }
}


#pragma mark - Custom property accessors

- (NSString *)countryCode
{
    return _placemark ? _placemark.ISOcountryCode : nil;
}


- (NSString *)country
{
    return self.countryCode ? [OUtil countryFromCountryCode:self.countryCode] : nil;
}


#pragma mark - CLLocationManagerDelegate conformance

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    [manager stopUpdatingLocation];
    
    [[[CLGeocoder alloc] init] reverseGeocodeLocation:manager.location completionHandler:^(NSArray *placemarks, NSError *error) {
        _placemark = placemarks[0];
        
        [_delegate locatorDidLocate];
    }];
}


- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusDenied) {
        [_delegate locatorCannotLocate];
    }
}

@end
