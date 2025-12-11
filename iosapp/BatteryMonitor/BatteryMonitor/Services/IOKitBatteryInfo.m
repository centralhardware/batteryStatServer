#import "IOKitBatteryInfo.h"
#import <Foundation/Foundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/ps/IOPowerSources.h>
#include <IOKit/ps/IOPSKeys.h>

@implementation IOKitBatteryInfo

+ (NSDictionary *)getBatteryInfo {
    CFTypeRef powerSourcesInfo = IOPSCopyPowerSourcesInfo();
    if (!powerSourcesInfo) {
        return nil;
    }

    CFArrayRef powerSourcesList = IOPSCopyPowerSourcesList(powerSourcesInfo);
    if (!powerSourcesList) {
        CFRelease(powerSourcesInfo);
        return nil;
    }

    NSMutableDictionary *batteryInfo = [NSMutableDictionary dictionary];

    CFIndex count = CFArrayGetCount(powerSourcesList);
    for (CFIndex i = 0; i < count; i++) {
        CFTypeRef powerSource = CFArrayGetValueAtIndex(powerSourcesList, i);
        NSDictionary *description = (__bridge NSDictionary *)IOPSGetPowerSourceDescription(powerSourcesInfo, powerSource);

        if (!description) {
            continue;
        }

        // Проверяем что это батарея, а не внешний источник питания
        NSString *type = description[@kIOPSTypeKey];
        if (![type isEqualToString:@kIOPSInternalBatteryType]) {
            continue;
        }

        // Текущая емкость
        NSNumber *currentCapacity = description[@kIOPSCurrentCapacityKey];
        if (currentCapacity) {
            batteryInfo[@"currentCapacity"] = currentCapacity;
        }

        // Максимальная емкость
        NSNumber *maxCapacity = description[@kIOPSMaxCapacityKey];
        if (maxCapacity) {
            batteryInfo[@"maxCapacity"] = maxCapacity;
        }

        // Дизайн емкость
        NSNumber *designCapacity = description[@"DesignCapacity"];
        if (designCapacity) {
            batteryInfo[@"designCapacity"] = designCapacity;
        }

        // Количество циклов
        NSNumber *cycleCount = description[@"CycleCount"];
        if (cycleCount) {
            batteryInfo[@"cycleCount"] = cycleCount;
        }

        // Напряжение (в вольтах)
        NSNumber *voltage = description[@kIOPSVoltageKey];
        if (voltage) {
            batteryInfo[@"voltage"] = voltage;
        }

        // Ток (в амперах)
        NSNumber *current = description[@kIOPSCurrentKey];
        if (current) {
            batteryInfo[@"current"] = current;
        }

        // Температура
        NSNumber *temperature = description[@"Temperature"];
        if (temperature) {
            batteryInfo[@"temperature"] = temperature;
        }

        // Статус зарядки
        NSNumber *isCharging = description[@kIOPSIsChargingKey];
        if (isCharging) {
            batteryInfo[@"isCharging"] = isCharging;
        }

        // Подключен ли адаптер питания
        NSNumber *powerConnected = description[@kIOPSPowerSourceStateKey];
        if (powerConnected) {
            batteryInfo[@"powerConnected"] = powerConnected;
        }

        // Health (если доступно)
        NSNumber *health = description[@"BatteryHealth"];
        if (health) {
            batteryInfo[@"health"] = health;
        }

        // Permanently Failed (если батарея требует замены)
        NSNumber *permanentlyFailed = description[@"PermanentFailureStatus"];
        if (permanentlyFailed) {
            batteryInfo[@"permanentlyFailed"] = permanentlyFailed;
        }

        break; // Используем первую найденную батарею
    }

    CFRelease(powerSourcesList);
    CFRelease(powerSourcesInfo);

    return [batteryInfo copy];
}

@end
