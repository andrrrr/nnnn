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
        
        //double minutesAggr = 0;
        for (HKCategorySample *sample in results) {

            NSTimeInterval distanceBetweenDates = [sample.endDate timeIntervalSinceDate:sample.startDate];
            double minutesInAnHour = 60;
            double minutesBetweenDates = distanceBetweenDates / minutesInAnHour;
            //minutesAggr += minutesBetweenDates;
            completion(minutesBetweenDates, error);
            
        }
//        completion(minutesAggr, error);
    }];
    
    [self executeQuery:query];
}


- (NSUInteger) getUsersAge {
    NSUInteger usersAge = 0;
    
    NSError *error;
    NSDate *dateOfBirth = [self dateOfBirthWithError:&error];
    
    if (!dateOfBirth) {
        NSLog(@"Either an error occured fetching the user's age information or none has been stored yet. In your app, try to handle this gracefully.");
    }
    else {
        // Compute the age of the user.
        NSDate *now = [NSDate date];
        
        NSDateComponents *ageComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:dateOfBirth toDate:now options:NSCalendarWrapComponents];
        
        usersAge = [ageComponents year];
        
    }
    return usersAge;
}

- (void)getUsersHeight:(void (^)(double, NSError *))completion2 {
    NSLengthFormatter *lengthFormatter = [[NSLengthFormatter alloc] init];
    lengthFormatter.unitStyle = NSFormattingUnitStyleLong;
    
    HKQuantityType *heightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    
    [self aapl_mostRecentQuantitySampleOfType:heightType predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSError *error) {
        if (!mostRecentQuantity) {
            NSLog(@"Either an error occured fetching the user's height information or none has been stored yet. In your app, try to handle this gracefully.");
            completion2(0, error);
           
        }
        else {
            // Determine the height in the required unit.
            
            HKUnit *heightUnit = [HKUnit meterUnitWithMetricPrefix:HKMetricPrefixCenti];
            double usersHeight = [mostRecentQuantity doubleValueForUnit:heightUnit];
            completion2(usersHeight, error);
            
        }
    }];
}


- (void)getUsersSteps:(void (^)(double, NSError *))completion2 {
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *interval = [[NSDateComponents alloc] init];
    interval.day = 1;
    
    NSDateComponents *anchorComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                                     fromDate:[NSDate date]];
    anchorComponents.hour = 0;
    NSDate *anchorDate = [calendar dateFromComponents:anchorComponents];
    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    // Create the query
    HKStatisticsCollectionQuery *query = [[HKStatisticsCollectionQuery alloc] initWithQuantityType:quantityType
                                                                           quantitySamplePredicate:nil
                                                                                           options:HKStatisticsOptionCumulativeSum
                                                                                        anchorDate:anchorDate
                                                                                intervalComponents:interval];
    
    // Set the results handler
    query.initialResultsHandler = ^(HKStatisticsCollectionQuery *query, HKStatisticsCollection *results, NSError *error) {
        if (error) {
            // Perform proper error handling here
            NSLog(@"*** An error occurred while calculating the statistics: %@ ***",error.localizedDescription);
        }
        
        NSDate *endDate = [NSDate date];
        NSDate *startDate = [calendar dateByAddingUnit:NSCalendarUnitDay
                                                 value:0
                                                toDate:endDate
                                               options:0];
        
        // Plot the daily step counts over the past x days
        [results enumerateStatisticsFromDate:startDate
                                      toDate:endDate
                                   withBlock:^(HKStatistics *result, BOOL *stop) {
                                       
                                       HKQuantity *quantity = result.sumQuantity;
                                       if (quantity) {
                                           NSDate *date = result.startDate;
                                           double value = [quantity doubleValueForUnit:[HKUnit countUnit]];
                                           NSLog(@"#### %@: %f", date, value);
                                           
                                           
                                           completion2(value, error);
                                       }
                                   }];
    };
    
    [self executeQuery:query];
    
}


- (void)getUsersWeight:(void (^)(double, NSError *))completion2 {
    
    HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    
    [self aapl_mostRecentQuantitySampleOfType:weightType predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSError *error) {
        if (!mostRecentQuantity) {
            NSLog(@"Either an error occured fetching the user's weight information or none has been stored yet. In your app, try to handle this gracefully.");
            completion2(0, error);
        }
        else {
            HKUnit *weightUnit = [HKUnit gramUnit];
            double usersWeight = [mostRecentQuantity doubleValueForUnit:weightUnit]/1000;
            
            completion2(usersWeight, error);
        }
    }];
}



- (void)getUsersSleep:(void (^)(double, NSError *))completion2 {
    [self hkQueryExecute: ^(double minutes, NSError *error) {
        if (minutes == 0) {
            NSLog(@"Either an error occured fetching the user's sleep information or none has been stored yet.");
            
            completion2(0, error);
        }
        else {
            int hours = (int)(minutes / 60);
            int minutesNew = (int)minutes - (hours*60);
            NSLog(@"minutes: %f ,hours slept: %ld:%ld", minutes, (long)hours, (long)minutesNew);
            
            completion2(minutes, error);
        }
    }];
}

- (void)getUsersHeartRate:(void (^)(double, NSError *))completion2 {
    HKQuantityType *heartRateType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    
    [self aapl_mostRecentQuantitySampleOfType:heartRateType predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSError *error) {
        if (!mostRecentQuantity) {
            NSLog(@"Either an error occured fetching the user's heart rate information or none has been stored yet. In your app, try to handle this gracefully.");
            completion2(0, error);
            
        }
        else {
            // Determine the weight in the required unit.
            HKUnit *heartRateUnit = [[HKUnit countUnit] unitDividedByUnit:[HKUnit minuteUnit]];
            double usersHR = [mostRecentQuantity doubleValueForUnit:heartRateUnit];

            completion2(usersHR, error);
        }
    }];
}




@end
