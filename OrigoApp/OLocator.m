//
//  OLocator.m
//  OrigoApp
//
//  Created by Anders Blehr on 29.04.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OLocator.h"

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#import "OMeta.h"
#import "OSettings.h"
#import "OState.h"
#import "OStrings.h"

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
    BOOL canLocate = NO;
    
    if ([CLLocationManager locationServicesEnabled]) {
        CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
        
        canLocate = ((authorizationStatus == kCLAuthorizationStatusNotDetermined) || (authorizationStatus == kCLAuthorizationStatusAuthorized));
    }
    
    return canLocate;
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
    NSString *countryCode = _placemark ? _placemark.ISOcountryCode : [OMeta m].settings.countryCode;
    
    if (!countryCode) {
        CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
        countryCode = [networkInfo subscriberCellularProvider].isoCountryCode;
        
        if (!countryCode) {
            countryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        }
    }
    
    return countryCode;
}


- (NSString *)country
{
    return [[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode value:self.countryCode];
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
