/*
    Copyright (C) 2015 IBM. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The main application delegate.
            
*/

//#import <IMFPush/IMFPush.h>
//#import "IMFURLProtocol.h"
#import <CloudantToolkit/CloudantToolkit.h>
//#import <CloudantSync.h>
//#import <IMFData/IMFData.h>
//#import "HKHealthStore+AAPLExtensions.h"

#import "IMFURLProtocol.h"
#import <IMFCore/IMFCore.h>



@import UIKit;
@import HealthKit;

@interface AAPLAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property UIBackgroundTaskIdentifier bgTask;

@property CDTStore *remotedatastore;
@property HKHealthStore *healthstore;


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


@end

