//
//  BSRNextBusAPIInterface.h
//  BUSR
//
//  Created by Vivek Seth on 9/22/14.
//  Copyright (c) 2014 Vivek Seth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSString * const BSRCampusBusch;
extern NSString * const BSRCampusCollegeAve;
extern NSString * const BSRCampusCookDouglass;
extern NSString * const BSRCampusLivingston;

/**
 Intention is for this class to provide data in a easy format for putting into database.
 Network => => Parse => Database => Application Use
 */
@interface BSRNextBusAPIInterface : NSObject

/** 
 Return:  array of dictionaries for all routes at Rutgers
 Format: { tag, title }[]
 */
+ (void)allRoutesWithCompletion:(void (^)(NSArray *routes))completion;

/**
 Return array of dictionaries for all unique stops for all routes
 Format {tag, title, latitude, longitude, stopID}[]
 */
+ (void)allStopsWithCompletion:(void (^)(NSArray *stops))completion;

/**
 Return array of dictionaries for all stops given routeTag
 Format {tag, title, latitude, longitude, stopID}[]
 */
+ (void)stopsForRouteTag:(NSString *)routeID completion:(void (^)(NSArray *stops))completion;

/** 
 return array of predictions for stopID
 Format: {routeTag, directionTitle, minutes}[]
 */
+ (void)predictionsForStopID:(NSString *)stopID completion:(void (^)(NSArray *predictions))completion;

/**
 Converts stopID to campusID.
 If invalid stopID, returns nil.
 */
+ (NSString *)campusIDForStopID:(NSString *)stopID;

@end

