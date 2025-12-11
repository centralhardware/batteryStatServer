#ifndef IOKitBatteryInfo_h
#define IOKitBatteryInfo_h

#import <Foundation/Foundation.h>

@interface IOKitBatteryInfo : NSObject

+ (NSDictionary * _Nullable)getBatteryInfo;

@end

#endif /* IOKitBatteryInfo_h */
