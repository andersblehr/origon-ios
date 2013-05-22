//
//  OLocator.h
//  OrigoApp
//
//  Created by Anders Blehr on 29.04.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

@protocol OLocatorDelegate;

@interface OLocator : NSObject<CLLocationManagerDelegate> {
@private
    CLLocationManager *_locationManager;
    CLPlacemark *_placemark;
}

@property (weak, nonatomic, readonly) NSString *countryCode;
@property (weak, nonatomic, readonly) NSString *country;

@property (weak, nonatomic) id<OLocatorDelegate> delegate;

- (BOOL)canLocate;
- (void)locate;

@end
