/*
     Copyright (C) 2015 IBM. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
 
    Abstract:
    
                Contains shared helper methods on HKHealthStore that are specific to Fit's use cases.
            
*/

@import HealthKit;



@interface HKHealthStore (AAPLExtensions)


- (void)aapl_mostRecentQuantitySampleOfType:(HKQuantityType *)quantityType predicate:(NSPredicate *)predicate completion:(void (^)(HKQuantity *mostRecentQuantity, NSError *error))completion;

- (void)hkQueryExecute: (void (^)(double, NSError *))completion;


@end
