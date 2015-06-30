//
//  healthKit.m
//  Fit
//
//  Created by andrew on 29-06-15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

#import "healthKit.h"
#import "HKHealthStore+AAPLExtensions.h"
#import "AAPLProfileViewController.h"
#import "AAPLEnergyViewController.h"
#import "Today.h"

@implementation healthKit


int counterObservers;
int counterObservers2;



 

- (void) getUsersAge:(void (^)(double, NSError *))completion2 {
    
    self.healthStore = [[HKHealthStore alloc] init];
    
    NSUInteger usersAge = 0;
    
    NSError *error;
    NSDate *dateOfBirth = [self.healthStore dateOfBirthWithError:&error];
    
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
    
    [self.healthStore aapl_mostRecentQuantitySampleOfType:heightType predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSError *error) {
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
                                           
                                           self.stepsYesterday = value;
                                           completion2(value, error);
                                       }else{
                                           self.stepsYesterday = 0;
                                           completion2(0, error);

                                       }
                                   }];
    };
    
    [self.healthStore executeQuery:query];
    
}



//calories ======================
//- (void)getCaloriesBurned {
//
//    NSLog(@"BEFORE");
//    self.aaplController = [[AAPLEnergyViewController alloc] init];
//    [self.aaplController refreshStatistics:^(double activeEnergyBurned, double restingEnergyBurned, double energyConsumed, double netEnergy) {
//        NSLog(@"EVERYTHING : %f, %f, %f, %f", activeEnergyBurned, restingEnergyBurned, energyConsumed, netEnergy);
//    }];
//}
//calories ======================


- (void)getUsersWeight:(void (^)(double, NSError *))completion2 {
    
    HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    
    [self.healthStore aapl_mostRecentQuantitySampleOfType:weightType predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSError *error) {
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
    [self.healthStore hkQueryExecute: ^(double minutes, NSError *error) {
        if (minutes == 0) {
            NSLog(@"Either an error occured fetching the user's sleep information or none has been stored yet.");
            self.sleepMinutesYesterday = 0;
            completion2(0, error);
        }
        else {
            int hours = (int)(minutes / 60);
            int minutesNew = (int)minutes - (hours*60);
            NSLog(@"minutes: %f ,hours slept: %ld:%ld", minutes, (long)hours, (long)minutesNew);
            self.sleepMinutesYesterday = minutes;
            completion2(minutes, error);
        }
    }];
}

- (void)getUsersHeartRate:(void (^)(double, NSError *))completion2 {
    HKQuantityType *heartRateType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    
    [self.healthStore aapl_mostRecentQuantitySampleOfType:heartRateType predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSError *error) {
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







- (double)calculateIndex {
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
    if (self.stepsYesterday < 3000) scoreMovement = 0;
    else if (self.stepsYesterday >= 3000 && self.stepsYesterday < 7500) scoreMovement = 1;
    else if (self.stepsYesterday >= 7500 && self.stepsYesterday < 10000) scoreMovement = 2;
    else if (self.stepsYesterday >= 10000 && self.stepsYesterday < 15000) scoreMovement = 3;
    else if (self.stepsYesterday >= 15000 && self.stepsYesterday < 17500) scoreMovement = 2;
    else if (self.stepsYesterday >= 17500 && self.stepsYesterday < 20000) scoreMovement = 1;
    else if (self.stepsYesterday > 20000) scoreMovement = 0;
    
    
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
    return physicalFitnessScore;
    
    
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

-(double)calculateBMI {
    double BMI = 0;
    if(self.heightYesterday!=0){
        BMI = 100*100*(double)self.weightYesterday/((double)self.heightYesterday*(double)self.heightYesterday);
        NSLog(@"BMI: %f", BMI);
    }
    self.BMI = BMI;
    return BMI;
}




//typedef void(^myCompletion)(Today *today);

//- (void)getYesterday:(void(^)(Today *today)) myCompletion {
//self.healthStore = [[HKHealthStore alloc] init];

- (void)getYesterday{
    
//    dispatch_group_t group = dispatch_group_create();
    
    [self registerObserversAndCalculateIndex];
    [self registerObserversForIndexAndBMI];
    
//    dispatch_group_async(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        //get age
        [self getUsersAge:^(double age, NSError *error) {
            self.ageYesterday = age;
        }];
        
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
        
        NSLog(@"AAAAAAGGRGGGRGRGRG");
        //        NSLog(@"### physicalFitnessScoreYesterday, %ld", (long)self.physicalFitnessScoreYesterday);
        //        NSLog(@"### stepsYest, %ld", (long)self.stepsYesterday);
        //        NSLog(@"### ageYest, %ld", (long)self.ageYesterday);
        //        NSLog(@"### heightYesterday, %ld", (long)self.heightYesterday);
        //        NSLog(@"### weightYesterday, %ld", (long)self.weightYesterday);
        //        NSLog(@"### sleepMinutesYesterday, %ld", (long)self.sleepMinutesYesterday);
        
//    });
    
    
    
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


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
//        NSLog(@"******^^^^^^^^ From KVO");
//    NSLog(@"******^^^^^^^^ counterObservers, %d", counterObservers);
//    NSLog(@"******^^^^^^^^ counterObservers2, %d", counterObservers2);
    
    if([keyPath isEqualToString:@"stepsYesterday"])
    {
        NSLog(@"******^^^^^^^^ steps");
        counterObservers += 1;
        [self removeObserver:self forKeyPath:@"stepsYesterday"];
        
    }
    if([keyPath isEqualToString:@"ageYesterday"])
    {
        NSLog(@"******^^^^^^^^ age");
        counterObservers += 1;
        [self removeObserver:self forKeyPath:@"ageYesterday"];
        
    }
    if([keyPath isEqualToString:@"heightYesterday"])
    {
        NSLog(@"******^^^^^^^^ height");
        counterObservers += 1;
        [self removeObserver:self forKeyPath:@"heightYesterday"];
        
    }
    if([keyPath isEqualToString:@"weightYesterday"])
    {
        NSLog(@"******^^^^^^^^ weight");
        counterObservers += 1;
        [self removeObserver:self forKeyPath:@"weightYesterday"];
        
    }
    if([keyPath isEqualToString:@"sleepMinutesYesterday"])
    {
        NSLog(@"******^^^^^^^^ sleep");
        counterObservers += 1;
        [self removeObserver:self forKeyPath:@"sleepMinutesYesterday"];
        
    }
    if([keyPath isEqualToString:@"heartRateYesterday"])
    {
        NSLog(@"******^^^^^^^^ heart");
        counterObservers += 1;
        [self removeObserver:self forKeyPath:@"heartRateYesterday"];
        
    }
    if([keyPath isEqualToString:@"physicalFitnessIndex"])
    {
        NSLog(@"******^^^^^^^^ fitness");
        counterObservers2 += 1;
        [self removeObserver:self forKeyPath:@"physicalFitnessIndex"];
        
    }
    if([keyPath isEqualToString:@"BMI"])
    {
        NSLog(@"******^^^^^^^^ BMI");
        counterObservers2 += 1;
        [self removeObserver:self forKeyPath:@"BMI"];
        
    }
    
    if(counterObservers == 6){
        NSLog(@"launching bmi fp");
        self.physicalFitnessIndex = [self calculateIndex];
        self.BMI = [self calculateBMI];
    }
    
    if(counterObservers2 == 2){
        NSDate *todayDate =[NSDate date];
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDateComponents *components = [[NSDateComponents alloc] init];
        [components setDay:-1];
        NSDate *yesterday = [cal dateByAddingComponents:components toDate:todayDate options:0];
        
//        NSString *userMail = @"aa";
        
//        Today *today = [[Today alloc] initWithDate:yesterday
//                              physicalFitnessScore:(NSInteger)0
//                                         userEmail:userMail
//                                             steps:(NSInteger)0
//                                    caloriesBurned:(NSInteger)0
//                                         heartRate:(NSInteger)0
//                                      sleepMinutes:(NSInteger)0
//                                            height:(NSInteger)0
//                                            weight:(NSInteger)0
//                                               age:(NSInteger)0
//                                           groupId:(NSInteger)0];
        
        
        Today *today2 = [[Today alloc] initWithDate:yesterday
                               physicalFitnessScore:self.physicalFitnessScoreYesterday
                                          userEmail:@""
                                              steps:self.stepsYesterday
                                     caloriesBurned:self.caloriesBurnedYesterday
                                          heartRate:self.heartRateYesterday
                                       sleepMinutes:self.sleepMinutesYesterday
                                             height:self.heightYesterday
                                             weight:self.weightYesterday
                                                age:self.ageYesterday
                                            groupId:self.groupIdYesterday];
        
        
        NSLog(@"TODAY:::::::::: %@", today2);
        
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
}


@end

