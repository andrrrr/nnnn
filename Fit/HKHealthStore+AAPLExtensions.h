/*
     Copyright (C) 2015 IBM. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
 
    Abstract:
    
                Contains shared helper methods on HKHealthStore that are specific to Fit's use cases.
            
*/

@import HealthKit;



@interface HKHealthStore (AAPLExtensions)

//@property (nonatomic, retain) NSDate *stepBegin;
//@property (nonatomic, retain) NSDate *stepEnd;



// Fetches the single most recent quantity of the specified type.
- (void)aapl_mostRecentQuantitySampleOfType:(HKQuantityType *)quantityType predicate:(NSPredicate *)predicate completion:(void (^)(HKQuantity *mostRecentQuantity, NSError *error))completion;

//- (void)readUsersStepFromHK:(NSDate*)startDate end:(NSDate*)endDate;
//
//- (void)fetchMostRecentDataOfQuantityType:(HKQuantityType *)quantityType withCompletion:(void (^)(HKQuantity *mostRecentQuantity, NSError *error))completion;

@end
