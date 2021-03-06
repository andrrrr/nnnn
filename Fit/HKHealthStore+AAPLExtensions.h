/*
     Copyright (C) 2015 IBM. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
 
    Abstract:
    
                Contains shared helper methods on HKHealthStore that are specific to Fit's use cases.
            
*/

#import <CloudantToolkit/CloudantToolkit.h>
#import <CloudantSync.h>
#import "Today.h"

@import HealthKit;



@interface HKHealthStore (AAPLExtensions)


- (void)aapl_mostRecentQuantitySampleOfType:(HKQuantityType *)quantityType predicate:(NSPredicate *)predicate completion:(void (^)(HKQuantity *mostRecentQuantity, NSError *error))completion;

- (void)hkQueryExecute: (void (^)(double, NSError *))completion;

//- (void)getYesterday:(void(^)(Today *today)) myCompletion;

- (void)getYesterday;

- (void) getUsersAge:(void (^)(double, NSError *))completion2;
- (void)getUsersHeight:(void (^)(double, NSError *))completion2;
- (void)getUsersSteps:(void (^)(double, NSError *))completion2;
- (void)getUsersWeight:(void (^)(double, NSError *))completion2;
- (void)getUsersSleep:(void (^)(double, NSError *))completion2;
- (void)getUsersHeartRate:(void (^)(double, NSError *))completion2;
- (void)getUsersEnergyBurned:(void (^)(double, NSError *))completion2;


@property CDTStore *remotedatastore;
@property HKHealthStore *healthStore;


@property NSInteger stepsYesterday;
@property NSInteger caloriesBurnedYesterday;
@property NSInteger heartRateYesterday;
@property NSInteger sleepMinutesYesterday;
@property NSInteger heightYesterday;
@property NSInteger weightYesterday;
@property NSInteger ageYesterday;
@property NSInteger sexYesterday;
@property NSInteger groupIdYesterday;
@property NSInteger physicalFitnessScoreYesterday;

@property double physicalFitnessIndex;
@property double BMI;

@end
