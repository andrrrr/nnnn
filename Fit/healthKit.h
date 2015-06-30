//
//  healthKit.h
//  Fit
//
//  Created by andrew on 29-06-15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CloudantToolkit/CloudantToolkit.h>
#import <CloudantSync.h>
#import "Today.h"
#import "AAPLEnergyViewController.h"

@import HealthKit;

@interface healthKit : NSObject


- (void)getYesterday;

- (void) getUsersAge:(void (^)(double, NSError *))completion2;
- (void)getUsersHeight:(void (^)(double, NSError *))completion2;
- (void)getUsersSteps:(void (^)(double, NSError *))completion2;
- (void)getUsersWeight:(void (^)(double, NSError *))completion2;
- (void)getUsersSleep:(void (^)(double, NSError *))completion2;
- (void)getUsersHeartRate:(void (^)(double, NSError *))completion2;

- (void)getCaloriesBurned;

@property CDTStore *remotedatastore;
@property HKHealthStore *healthStore;
@property AAPLEnergyViewController* aaplController;


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
