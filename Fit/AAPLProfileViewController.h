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
#import "IMFFacebookAuthenticationHandler.h"
#import "IMFGoogleAuthenticationHandler.h"
#import <IMFPush/IMFPush.h>
#import "IMFURLProtocol.h"
#import <IMFCore/IMFCore.h>
#import <GooglePlus/GooglePlus.h>


@import UIKit;
@import HealthKit;

@interface AAPLProfileViewController : UITableViewController <GPPSignInDelegate>



@property (nonatomic) HKHealthStore *healthStore;
- (IBAction)sendData:(id)sender;

@end
