//
//  OLocator.h
//  OrigoApp
//
//  Created by Anders Blehr on 29.04.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

@interface OLocator : NSObject<CLLocationManagerDelegate> {
@private
    CLLocationManager *_locationManager;
    CLPlacemark *_placemark;
}

@property (strong, nonatomic, readonly) NSString *countryCode;
@property (strong, nonatomic, readonly) NSString *country;

- (BOOL)canUseLocationServices;
- (void)locate;

@end
