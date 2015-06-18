/*
     Copyright (C) 2015 IBM. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
 
    Abstract:
    
                Contains shared helper methods on HKHealthStore that are specific to Fit's use cases.
            
*/

#import "HKHealthStore+AAPLExtensions.h"
#import "AAPLProfileViewController.h"

@implementation HKHealthStore (AAPLExtensions)

- (void)aapl_mostRecentQuantitySampleOfType:(HKQuantityType *)quantityType predicate:(NSPredicate *)predicate completion:(void (^)(HKQuantity *, NSError *))completion {
    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    
    // Since we are interested in retrieving the user's latest sample, we sort the samples in descending order, and set the limit to 1. We are not filtering the data, and so the predicate is set to nil.
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:quantityType predicate:nil limit:1 sortDescriptors:@[timeSortDescriptor] resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if (!results) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        
        if (completion) {
            // If quantity isn't in the database, return nil in the completion block.
            HKQuantitySample *quantitySample = results.firstObject;
            HKQuantity *quantity = quantitySample.quantity;
            
            completion(quantity, error);
        }
    }];
    
    [self executeQuery:query];
}


- (void)hkQueryExecute:(void (^)(double, NSError *))completion {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *now = [NSDate date];
    
    NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
    
    NSDate *startDate = [calendar dateFromComponents:components];
    
    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
    
    HKSampleType *sampleType = [HKSampleType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
    
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:0 sortDescriptors:nil resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if (!results) {
            NSLog(@"An error occured fetching the user's sleep duration. In your app, try to handle this gracefully. The error was: %@.", error);
            completion(0, error);
            abort();
        }
        
        double minutesAggr = 0;
        for (HKCategorySample *sample in results) {

            NSTimeInterval distanceBetweenDates = [sample.endDate timeIntervalSinceDate:sample.startDate];
            double minutesInAnHour = 60;
            double minutesBetweenDates = distanceBetweenDates / minutesInAnHour;
            minutesAggr += minutesBetweenDates;
            
        }
        completion(minutesAggr, error);
    }];
    
    [self executeQuery:query];
}







@end
