/*
 Copyright (C) 2015 IBM. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
    Abstract:
    
                Displays age, height, and weight information retrieved from HealthKit.
            
*/

#import <CloudantToolkit/CloudantToolkit.h>
#import <CloudantSync.h>
#import <IMFData/IMFData.h>
#import "Today.h"
#import "IMFGoogleAuthenticationHandler.h"
#import <IMFPush/IMFPush.h>
#import "IMFURLProtocol.h"
#import <IMFCore/IMFCore.h>
#import <GooglePlus/GooglePlus.h>


@import UIKit;
@import HealthKit;

@interface AAPLProfileViewController : UITableViewController <GPPSignInDelegate>

// Note that the user's age is not editable.
@property (nonatomic, weak) IBOutlet UILabel *ageUnitLabel;
@property (nonatomic, weak) IBOutlet UILabel *ageValueLabel;

@property (nonatomic, weak) IBOutlet UILabel *heightValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *heightUnitLabel;

@property (nonatomic, weak) IBOutlet UILabel *weightValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *weightUnitLabel;

@property (nonatomic, weak) IBOutlet UILabel *stepsValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *stepsUnitLabel;

@property (strong, nonatomic) IBOutlet UILabel *heartRateLabel;

@property (weak, nonatomic) IBOutlet UILabel *sleepDurationLabel;
@property (weak, nonatomic) IBOutlet UILabel *sleepDurationValueLabel;
@property (strong, nonatomic) IBOutlet UILabel *indexLabel;

@property NSInteger countQueries;

@property NSInteger stepsYesterday;
@property NSInteger caloriesBurnedYesterday;
@property NSInteger heartRateYesterday;
@property NSInteger sleepMinutesYesterday;
@property NSInteger heightYesterday;
@property NSInteger weightYesterday;
@property NSInteger ageYesterday;
@property NSInteger sexYesterday;



@property CDTStore *remotedatastore;



@property (nonatomic) HKHealthStore *healthStore;

+ (AAPLProfileViewController *)sharedInstanceOfMe;

- (IBAction)sendData:(id)sender;
- (void) saveDataToDb;

@end
