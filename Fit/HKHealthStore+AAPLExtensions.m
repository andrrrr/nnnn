/*
     Copyright (C) 2015 IBM. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
 
    Abstract:
    
                Contains shared helper methods on HKHealthStore that are specific to Fit's use cases.
            
*/

#import "HKHealthStore+AAPLExtensions.h"
#import "AAPLProfileViewController.h"

@implementation HKHealthStore (AAPLExtensions)

int counterObservers;
int counterObservers2;

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

- (void)fetchSumOfSamplesTodayForType:(HKQuantityType *)quantityType unit:(HKUnit *)unit completion:(void (^)(double, NSError *))completionHandler {
    NSPredicate *predicate = [self predicateForSamplesToday];
    
    HKStatisticsQuery *query = [[HKStatisticsQuery alloc] initWithQuantityType:quantityType quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
        HKQuantity *sum = [result sumQuantity];
        
        if (completionHandler) {
            double value = [sum doubleValueForUnit:unit];
            
            completionHandler(value, error);
        }
    }];
    [self executeQuery:query];
}

- (NSPredicate *)predicateForSamplesToday {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *now = [NSDate date];
    
    NSDate *startDate = [calendar startOfDayForDate:now];
    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
    
    return [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
}

- (void)getUsersEnergyBurned:(void (^)(double, NSError *))completion2 {
    HKQuantityType *activeEnergyBurnType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
    
    [self fetchSumOfSamplesTodayForType:activeEnergyBurnType unit:[HKUnit jouleUnit] completion:^(double activeEnergyBurned, NSError *error) {
        
//        self.caloriesBurnedYesterday = (double)activeEnergyBurned * (double)0.239005736;
//        NSLog(@"CAL : %ld", (long)self.caloriesBurnedYesterday);
        
        completion2(activeEnergyBurned, error);
    }];
}






- (void) getUsersAge:(void (^)(double, NSError *))completion2 {
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
    completion2(usersAge, error);
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
            completion2(0, error);
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





- (void)calculateIndex {
    int scoreMovement;
    int scoreSleep;
    int scoreHeartRate;
    
    double physicalFitnessScore;
    
    NSLog(@"### calculateIndex: stepsYest, %ld", (long)self.stepsYesterday);
    NSLog(@"### calculateIndex: ageYest, %ld", (long)self.ageYesterday);
    NSLog(@"### calculateIndex: heightYesterday, %ld", (long)self.heightYesterday);
    NSLog(@"### calculateIndex: weightYesterday, %ld", (long)self.weightYesterday);
    NSLog(@"### calculateIndex: sleepMinutesYesterday, %ld", (long)self.sleepMinutesYesterday);
    NSLog(@"### calculateIndex: heartRateYesterday, %ld", (long)self.heartRateYesterday);
    
    //calculate score movement
    double stepsFromCalories = 0;
    stepsFromCalories = (double)self.caloriesBurnedYesterday / (double)0.04;
    double stepsAll =self.stepsYesterday + stepsFromCalories;
    
    if (stepsAll < 3000) scoreMovement = 0;
    else if (stepsAll >= 3000 && stepsAll < 7500) scoreMovement = 1;
    else if (stepsAll >= 7500 && stepsAll < 10000) scoreMovement = 2;
    else if (stepsAll >= 10000 && stepsAll < 15000) scoreMovement = 3;
    else if (stepsAll >= 15000 && stepsAll < 17500) scoreMovement = 2;
    else if (stepsAll >= 17500 && stepsAll < 20000) scoreMovement = 1;
    else if (stepsAll > 20000) scoreMovement = 0;
    
    
    //calculate score sleep
    if (self.sleepMinutesYesterday < 360 || self.sleepMinutesYesterday > 600) scoreSleep = 0;
    else if ((self.sleepMinutesYesterday >=360 && self.sleepMinutesYesterday <420) || (self.sleepMinutesYesterday >=540 && self.sleepMinutesYesterday <600)) scoreSleep = 1;
    else if ((self.sleepMinutesYesterday >=420 && self.sleepMinutesYesterday <450) || (self.sleepMinutesYesterday >=510 && self.sleepMinutesYesterday <540)) scoreSleep = 2;
    else if (self.sleepMinutesYesterday >= 450 || self.sleepMinutesYesterday < 510) scoreSleep = 3;
    
    
    //calculate score heart rate
    if(self.heartRateYesterday<=39 || self.heartRateYesterday>=100 )scoreHeartRate = 0;
    else if(self.heartRateYesterday>=40 && self.heartRateYesterday<=49 )scoreHeartRate = 3;
    else if(self.heartRateYesterday>=50 && self.heartRateYesterday<=59 )scoreHeartRate = 2;
    else if(self.heartRateYesterday>=60 && self.heartRateYesterday<=99 )scoreHeartRate = 1;
    
    NSLog(@"scoreMOVEMENT  %d", scoreMovement);
    NSLog(@"scoreSLEEP  %d", scoreSleep);
    NSLog(@"scoreHR  %d", scoreHeartRate);
    physicalFitnessScore = (scoreMovement*0.55 + scoreSleep*0.2 + scoreHeartRate*0.25)*100;
    NSLog(@"physicalFitnessScore  %f", physicalFitnessScore);
    self.physicalFitnessScoreYesterday = physicalFitnessScore;
//    return physicalFitnessScore;
    
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.indexLabel.text = [NSNumberFormatter localizedStringFromNumber:@(physicalFitnessScore) numberStyle:NSNumberFormatterDecimalStyle];
//        
//    });
    
    
//    self.BMIlabel.text = @"";
//    double BMI = 0;
//    if(self.heightYesterday!=0){
//        BMI = 100*100*(double)self.weightYesterday/((double)self.heightYesterday*(double)self.heightYesterday);
//        NSLog(@"BMI: %f", BMI);
//    }
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.BMIlabel.text = [NSNumberFormatter localizedStringFromNumber:@(BMI) numberStyle:NSNumberFormatterNoStyle];
//    });
}

-(void)calculateBMI {
    double BMI = 0;
    if(self.heightYesterday!=0){
        BMI = 100*100*(double)self.weightYesterday/((double)self.heightYesterday*(double)self.heightYesterday);
        NSLog(@"BMI: %f", BMI);
    }
    self.BMI = BMI;

}




//typedef void(^myCompletion)(Today *today);

//- (void)getYesterday:(void(^)(Today *today)) myCompletion {
    //self.healthStore = [[HKHealthStore alloc] init];
    
- (void)getYesterday{
    
    dispatch_group_t group = dispatch_group_create();
    
    [self registerObserversAndCalculateIndex];
    [self registerObserversForIndexAndBMI];
    
    dispatch_group_async(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        //get age
        //self.ageYesterday = [self getUsersAge];
        
        //get height
        [self getUsersHeight:^(double height, NSError *error) {
            self.heightYesterday = height;
        }];
        
        //get weight
        [self getUsersWeight:^(double kilos, NSError *error) {
            self.weightYesterday = kilos;
        }];
        
        //get steps
        [self getUsersSteps:^(double steps, NSError *error) {
            self.stepsYesterday = steps;
        }];
        
        //get sleep
        [self getUsersSleep: ^(double minutes, NSError *error) {
            self.sleepMinutesYesterday = minutes;
        }];
        
        //get heart
        [self getUsersHeartRate:^(double beats, NSError *error) {
            self.heartRateYesterday = beats;
        }];
        
        [self getUsersEnergyBurned:^(double calories, NSError *error) {
            self.caloriesBurnedYesterday = calories;
        }];
        
        NSLog(@"AAAAAAGGRGGGRGRGRG");
//        NSLog(@"### physicalFitnessScoreYesterday, %ld", (long)self.physicalFitnessScoreYesterday);
//        NSLog(@"### stepsYest, %ld", (long)self.stepsYesterday);
//        NSLog(@"### ageYest, %ld", (long)self.ageYesterday);
//        NSLog(@"### heightYesterday, %ld", (long)self.heightYesterday);
//        NSLog(@"### weightYesterday, %ld", (long)self.weightYesterday);
//        NSLog(@"### sleepMinutesYesterday, %ld", (long)self.sleepMinutesYesterday);
        
    });
    
    
    
//    dispatch_group_notify(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
    
//        NSDate *todayDate =[NSDate date];
//        NSCalendar *cal = [NSCalendar currentCalendar];
//        NSDateComponents *components = [[NSDateComponents alloc] init];
//        [components setDay:-1];
//        NSDate *yesterday = [cal dateByAddingComponents:components toDate:todayDate options:0];
//        
//        Today *today = [[Today alloc] initWithDate:yesterday physicalFitnessScore:0 userEmail:@"" steps:self.stepsYesterday caloriesBurned:self.caloriesBurnedYesterday heartRate:self.heartRateYesterday sleepMinutes:self.sleepMinutesYesterday height:self.heightYesterday weight:self.weightYesterday age:self.ageYesterday groupId:self.groupIdYesterday];
//        
//        myCompletion(today);
//    });
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //    NSLog(@"******^^^^^^^^ From KVO");
    
    if([keyPath isEqualToString:@"stepsYesterday"])
    {
        counterObservers += 1;
        [self removeObserver:self forKeyPath:@"stepsYesterday"];
        
    }
    if([keyPath isEqualToString:@"ageYesterday"])
    {
        counterObservers += 1;
        [self removeObserver:self forKeyPath:@"ageYesterday"];
        
    }
    if([keyPath isEqualToString:@"heightYesterday"])
    {
        counterObservers += 1;
        [self removeObserver:self forKeyPath:@"heightYesterday"];
        
    }
    if([keyPath isEqualToString:@"weightYesterday"])
    {
        counterObservers += 1;
        [self removeObserver:self forKeyPath:@"weightYesterday"];
        
    }
    if([keyPath isEqualToString:@"sleepMinutesYesterday"])
    {
        counterObservers += 1;
        [self removeObserver:self forKeyPath:@"sleepMinutesYesterday"];
        
    }
    if([keyPath isEqualToString:@"heartRateYesterday"])
    {
        counterObservers += 1;
        [self removeObserver:self forKeyPath:@"heartRateYesterday"];
        
    }
    if([keyPath isEqualToString:@"caloriesBurnedYesterday"])
    {
        counterObservers += 1;
        [self removeObserver:self forKeyPath:@"caloriesBurnedYesterday"];
        
    }
    
    
    if([keyPath isEqualToString:@"physicalFitnessIndex"])
    {
        counterObservers2 += 1;
        [self removeObserver:self forKeyPath:@"physicalFitnessIndex"];
    }
    
    if([keyPath isEqualToString:@"BMI"])
    {
        counterObservers2 += 1;
        [self removeObserver:self forKeyPath:@"BMI"];
    }
    
    
    
    if(counterObservers == 7){
        [self calculateIndex];
        [self calculateBMI];
    }
    
    if(counterObservers2 == 2){
        NSDate *todayDate =[NSDate date];
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDateComponents *components = [[NSDateComponents alloc] init];
        [components setDay:-1];
        NSDate *yesterday = [cal dateByAddingComponents:components toDate:todayDate options:0];
        
        Today *today = [[Today alloc] initWithDate:yesterday physicalFitnessScore:self.physicalFitnessScoreYesterday userEmail:@"" steps:self.stepsYesterday caloriesBurned:self.caloriesBurnedYesterday heartRate:self.heartRateYesterday sleepMinutes:self.sleepMinutesYesterday height:self.heightYesterday weight:self.weightYesterday age:self.ageYesterday groupId:self.groupIdYesterday];
        NSLog(@"TODAY:::::::::: %@", today);
    }
}

- (void)registerObserversForIndexAndBMI
{
    counterObservers2 = 0;
    [self addObserver:self forKeyPath:@"physicalFitnessIndex" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"BMI" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}


- (void)registerObserversAndCalculateIndex
{
    counterObservers = 0;
    [self addObserver:self forKeyPath:@"stepsYesterday" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"ageYesterday" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"heightYesterday" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"weightYesterday" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"sleepMinutesYesterday" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"heartRateYesterday" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"caloriesBurnedYesterday" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

@end
