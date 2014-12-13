//
//  BSRNextBusAPIInterface.m
//  BUSR
//
//  Created by Vivek Seth on 9/22/14.
//  Copyright (c) 2014 Vivek Seth. All rights reserved.
//

#import "BSRNextBusAPIInterface.h"

#import <AFNetworking/AFNetworking.h>
#import <RaptureXML/RXMLElement.h>

static NSString * const BSRNextBusAPIURL = @"http://webservices.nextbus.com/service/publicXMLFeed";

NSString * const BSRCampusBusch = @"BSRCampusBusch";
NSString * const BSRCampusCollegeAve = @"BSRCampusCollegeAve";
NSString * const BSRCampusCookDouglass = @"BSRCampusCookDouglass";
NSString * const BSRCampusLivingston = @"BSRCampusLivingston";

@implementation BSRNextBusAPIInterface

#pragma mark - Public Next Bus API Interface

+ (void)allRoutesWithCompletion:(void (^)(NSArray *routes))completion {
	NSParameterAssert(completion);

	[[self class] APIRequestWithParameters:@{@"command":@"routeList"}
								   success:^(AFHTTPRequestOperation *operation, id responseObject) {
									   completion([[self class] routesForXMLData:responseObject]);
								   }
								   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
									   NSLog(@"Error: %@", error);
									   completion(nil);
								   }];
}

+ (void)allStopsWithCompletion:(void (^)(NSArray *stops))completion {
	NSParameterAssert(completion);

	[[self class] allRoutesWithCompletion:^(NSArray *routes) {
		// No Routes, cannot get stops
		if (!routes) {
			completion(nil);
			return;
		}

		__block NSMutableDictionary *tempStopDictionary = [@{} mutableCopy];
		__block NSInteger completedRoutes = 0;
		__block NSInteger attemptedRoutes = 0;

		[routes enumerateObjectsUsingBlock:^(NSDictionary *routeDict, NSUInteger routesEnumIdx, BOOL *routesEnumStop) {
			[[self class] stopsForRouteTag:routeDict[@"tag"] completion:^(NSArray *stops) {
				attemptedRoutes++;
				if (stops) {
					[stops enumerateObjectsUsingBlock:^(NSDictionary *stopDict, NSUInteger stopsEnumidx, BOOL *StopsEnumStop) {
						tempStopDictionary[stopDict[@"stopID"]] = stopDict;
					}];
					completedRoutes++;
				}

				// All routes tried.
				if (routes.count == attemptedRoutes) {
					// All routes completed succesfully
					if (routes.count == completedRoutes) {
						NSArray *stopKeys = [tempStopDictionary keysSortedByValueUsingComparator:^NSComparisonResult(NSDictionary *k1, NSDictionary *k2) {
							return [k1[@"stopID"] compare:k2[@"stopID"]];
						}];

						NSMutableArray *uniqueStops = [@[] mutableCopy];
						[stopKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
							[uniqueStops addObject:tempStopDictionary[key]];
						}];

						completion(uniqueStops);
					}
					// Not all routes completed succesfully
					else {
						completion(nil);
					}
				}
			}];
		}];
	}];
}

+ (void)stopsForRouteTag:(NSString *)routeID completion:(void (^)(NSArray *stops))completion {
	NSParameterAssert(routeID);
	NSParameterAssert(completion);

	[[self class] APIRequestWithParameters:@{@"command":@"routeConfig", @"r":routeID}
								   success:^(AFHTTPRequestOperation *operation, id responseObject) {
									   completion([[self class] stopsForXMLData:responseObject]);
								   }
								   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
									   NSLog(@"Error: %@", error);
									   completion(nil);
								   }];
}

+ (void)predictionsForStopID:(NSString *)stopID completion:(void (^)(NSArray *predictions))completion {
	NSParameterAssert(stopID);
	NSParameterAssert(completion);

	[[self class] APIRequestWithParameters:@{@"command":@"predictions", @"stopId":stopID}
								   success:^(AFHTTPRequestOperation *operation, id responseObject) {
									   completion([[self class] predictionsForXMLData:responseObject]);
								   }
								   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
									   NSLog(@"Error: %@", error);
									   completion(nil);
								   }];
}

#pragma mark - API Request Utility

+ (AFHTTPRequestOperationManager *)defualtRequestOperationManager {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	AFHTTPResponseSerializer * responseSerializer = [AFHTTPResponseSerializer serializer];
	responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/xml", nil];
	manager.responseSerializer = responseSerializer;

	return manager;
}

+ (void)APIRequestWithParameters:(NSDictionary *)parameters
						 success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
						 failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	[[[self class] defualtRequestOperationManager] GET:BSRNextBusAPIURL
											parameters:[[self class] appendParametersToDefault:parameters]
											   success:success
											   failure:failure];
}

+ (NSDictionary *)appendParametersToDefault:(NSDictionary *)parameters {
	NSDictionary * defaultParameters = @{@"a": @"rutgers"};
	NSMutableDictionary * newParameters = [NSMutableDictionary dictionaryWithDictionary:defaultParameters];
	[newParameters addEntriesFromDictionary:parameters];
	return [NSDictionary dictionaryWithDictionary:newParameters];
}

#pragma mark - API XML Response Methods

+ (NSArray *)routesForXMLData:(NSData *)xmlData {
	NSMutableArray *routes = [@[] mutableCopy];
	RXMLElement *rootXML = [RXMLElement elementFromXMLData:xmlData];

	[rootXML iterate:@"route" usingBlock:^(RXMLElement * element) {
		[routes addObject:@{@"tag": [element attribute:@"tag"],
							@"title": [element attribute:@"title"]}];
	}];

	return routes;
}

+ (NSArray *)stopsForXMLData:(NSData *)xmlData {
	NSMutableArray *stops = [@[] mutableCopy];
	RXMLElement *rootXML = [RXMLElement elementFromXMLData:xmlData];

	[rootXML iterate:@"route.stop" usingBlock:^(RXMLElement * element) {
		[stops addObject:@{@"tag": [element attribute:@"tag"],
						   @"title": [element attribute:@"title"],
						   @"latitude": [element attribute:@"lat"],
						   @"longitude": [element attribute:@"lon"],
						   @"stopID": [element attribute:@"stopId"]}];
	}];

	return stops;
}

+ (NSArray *)predictionsForXMLData:(NSData *)xmlData {
	NSMutableArray *predictions = [@[] mutableCopy];
	RXMLElement *rootXML = [RXMLElement elementFromXMLData:xmlData];

	[rootXML iterate:@"predictions" usingBlock:^(RXMLElement * predictionsContainerElement) {
		NSString *routeTag = [predictionsContainerElement attribute:@"routeTag"];
		[predictionsContainerElement iterate:@"direction" usingBlock:^(RXMLElement * directionElement) {
			NSString *directionTitle = [directionElement attribute:@"title"];
			[directionElement iterate:@"prediction" usingBlock:^(RXMLElement * predictionLeafElement) {
				[predictions addObject:@{@"routeTag": routeTag,
										 @"directionTitle": directionTitle,
										 @"minutes": [predictionLeafElement attribute:@"minutes"]}];
			}];
		}];
	}];

	return predictions;
}

#pragma mark - Utility

+ (NSString *)campusIDForStopID:(NSString *)stopID {
	NSDictionary * d = @{
						 @"1041": BSRCampusBusch,
						 @"1036": BSRCampusBusch,
						 @"1048": BSRCampusCookDouglass,
						 @"1037": BSRCampusCollegeAve,
						 @"1009": BSRCampusBusch,
						 @"1008": BSRCampusBusch,
						 @"1056": BSRCampusBusch,
						 @"1007": BSRCampusBusch,
						 @"1045": BSRCampusCookDouglass,
						 @"1052": BSRCampusCookDouglass,
						 @"1015": BSRCampusCookDouglass,
						 @"1042": BSRCampusCollegeAve,
						 @"1023": BSRCampusBusch,
						 @"1012": BSRCampusCookDouglass,
						 @"1051": BSRCampusCookDouglass,
						 @"1050": BSRCampusCookDouglass,
						 @"1004": BSRCampusBusch,
						 @"1066": BSRCampusBusch,
						 @"1014": BSRCampusCookDouglass,
						 @"1053": BSRCampusCollegeAve,
						 @"1006": BSRCampusCollegeAve,
						 @"1047": BSRCampusCookDouglass,
						 @"1028": BSRCampusLivingston,
						 @"1029": BSRCampusLivingston,
						 @"1058": BSRCampusLivingston,
						 @"1070": BSRCampusCollegeAve,
						 @"1067": BSRCampusCollegeAve,
						 @"1054": BSRCampusCollegeAve,
						 @"1016": BSRCampusCookDouglass,
						 @"1044": BSRCampusCookDouglass,
						 @"1030": BSRCampusLivingston,
						 @"1046": BSRCampusCookDouglass,
						 @"1011": BSRCampusCookDouglass,
						 @"1043": BSRCampusCollegeAve,
						 @"1062": BSRCampusCollegeAve,
						 @"1000": BSRCampusCollegeAve,
						 @"1005": BSRCampusBusch,
						 @"1055": BSRCampusCollegeAve,
						 @"1024": BSRCampusBusch,
						 @"1001": BSRCampusCollegeAve,
						 @"1061": BSRCampusCollegeAve,
						 @"1010": BSRCampusCollegeAve,
						 @"1060": BSRCampusCollegeAve,
						 @"1064": BSRCampusCollegeAve,
						 @"1071": BSRCampusBusch,
						 @"1003": BSRCampusBusch,
						 @"1022": BSRCampusBusch,
						 @"1017": BSRCampusCollegeAve,
						 };
	return d[stopID];
}

@end
