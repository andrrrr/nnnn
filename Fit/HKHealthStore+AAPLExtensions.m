/*
     Copyright (C) 2015 IBM. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
 
    Abstract:
    
                Contains shared helper methods on HKHealthStore that are specific to Fit's use cases.
            
*/

#import "HKHealthStore+AAPLExtensions.h"

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


//- (void)collectStatisticsQuery {
//    NSCalendar *calendar = [NSCalendar currentCalendar];
//    NSDateComponents *interval = [[NSDateComponents alloc] init];
//    interval.day = 7;
//    
//    // Set the anchor date to Monday at 3:00 a.m.
//    NSDateComponents *anchorComponents =
//    [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth |
//     NSCalendarUnitYear | NSCalendarUnitWeekday fromDate:[NSDate date]];
//    
//    NSInteger offset = (7 + anchorComponents.weekday - 2) % 7;
//    anchorComponents.day -= offset;
//    anchorComponents.hour = 3;
//    
//    NSDate *anchorDate = [calendar dateFromComponents:anchorComponents];
//    
//    HKQuantityType *quantityType =
//    [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
//    
//    // Create the query
//    HKStatisticsCollectionQuery *query =
//    [[HKStatisticsCollectionQuery alloc]
//     initWithQuantityType:quantityType
//     quantitySamplePredicate:nil
//     options:HKStatisticsOptionCumulativeSum
//     anchorDate:anchorDate
//     intervalComponents:interval];
//    
//    // Set the results handler
//    query.initialResultsHandler =
//    ^(HKStatisticsCollectionQuery *query, HKStatisticsCollection *results, NSError *error) {
//        
//        if (error) {
//            // Perform proper error handling here
//            NSLog(@"*** An error occurred while calculating the statistics: %@ ***",
//                  error.localizedDescription);
//            abort();
//        }
//        
//        NSDate *endDate = [NSDate date];
//        NSDate *startDate = [calendar
//                             dateByAddingUnit:NSCalendarUnitMonth
//                             value:-3
//                             toDate:endDate
//                             options:0];
//        
//        // Plot the weekly step counts over the past 3 months
//        [results
//         enumerateStatisticsFromDate:startDate
//         toDate:endDate
//         withBlock:^(HKStatistics *result, BOOL *stop) {
//             
//             HKQuantity *quantity = result.sumQuantity;
//             if (quantity) {
//                 NSDate *date = result.startDate;
//                 double value = [quantity doubleValueForUnit:[HKUnit countUnit]];
//                 
//                 [self plotData:value forDate:date];
//             }
//             
//         }];
//    };
//    
//    [self executeQuery:query];
//}



@end
