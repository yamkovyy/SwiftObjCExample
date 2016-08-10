//
//  LocationManager.h
//  TestCase
//
//  Created by viera on 8/3/16.
//  Copyright © 2016 vydeveloping. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LocationManagerDelegate <NSObject>

@required
- (void)locationDidRecivedWithLocation:(NSString *)location;

@end

@interface LocationManager : NSObject

@property (nonatomic, strong) id delegate;

+ (LocationManager*)sharedManager;
- (float)getCurrentLongitude;
- (float)getCurrentLatitude;
- (NSString*)getCurrentCity;

@end
