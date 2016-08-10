//
//  LocationManager.m
//  TestCase
//
//  Created by viera on 8/3/16.
//  Copyright © 2016 vydeveloping. All rights reserved.
//

#import "LocationManager.h"
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@interface LocationManager() <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *manager;
@property (nonatomic, strong) NSMutableArray *locations;
@property (nonatomic, strong) NSString *city;

@end

@implementation LocationManager

#pragma mark - Memory management
+ (LocationManager*)sharedManager
{
    static dispatch_once_t pred;
    static LocationManager *shared = nil;
    dispatch_once(&pred, ^{
        shared = [[LocationManager alloc] init];
        [shared initVariables];
        [shared configureLocationManager];
    });
    
    return shared;
}

#pragma mark - View LifeCycle

#pragma mark - Action Handlers

#pragma mark - Public
- (float)getCurrentLongitude
{
    CLLocation *location = self.locations.lastObject;
    return location.coordinate.longitude;
}

- (float)getCurrentLatitude
{
    CLLocation *location = self.locations.lastObject;
    return location.coordinate.latitude;
}

- (NSString*)getCurrentCity
{
    return self.city;
}

#pragma mark - Private
- (void)initVariables
{
    self.locations = [NSMutableArray new];
}

- (void)configureLocationManager
{
    self.manager = [[CLLocationManager alloc] init];
    self.manager.delegate = self;
    self.manager.distanceFilter = kCLDistanceFilterNone;
    self.manager.desiredAccuracy = kCLLocationAccuracyBest;
    [self.manager requestWhenInUseAuthorization];
    [self.manager startMonitoringSignificantLocationChanges];
    [self.manager startUpdatingLocation];
}

- (void)getCityFromLocation:(CLLocation*)location
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init] ;
    [geocoder reverseGeocodeLocation: location completionHandler:^(NSArray *placemarks, NSError *error)
     {
         if (!(error))
         {
             CLPlacemark *placemark = [placemarks objectAtIndex:0];
             NSLog(@"\nCurrent Location Detected\n");
             NSLog(@"placemark %@",placemark);
             NSString *area = [[NSString alloc]initWithString: placemark.locality];
             NSString *country = [[NSString alloc]initWithString: placemark.country];
             NSString *countryArea = [NSString stringWithFormat:@"%@, %@", area, country];
             NSLog(@"%@",countryArea);
             
             self.city = countryArea;
             
             if ([self.delegate respondsToSelector: @selector(locationDidRecivedWithLocation:)])
             {
                 [self.delegate locationDidRecivedWithLocation: countryArea];
                 [self.manager stopUpdatingLocation];
             }
         }
         else
         {
             NSLog(@"Geocode failed with error %@", error);
             NSLog(@"\nCurrent Location Not Detected\n");
         }
     }];
}

#pragma mark - Delegates

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"OldLocation %f %f", oldLocation.coordinate.latitude, oldLocation.coordinate.longitude);
    NSLog(@"NewLocation %f %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    [self.locations addObject: newLocation];
    [self getCityFromLocation: newLocation];
}

- (void)locationManager:(CLLocationManager*)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusNotDetermined: {
            NSLog(@"User still thinking..");
        } break;
        case kCLAuthorizationStatusDenied: {
            NSLog(@"User hates you");
        } break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusAuthorizedAlways: {
            [self.manager startUpdatingLocation];
        } break;
        default:
            break;
    }
}
@end
