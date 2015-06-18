//
//  Today.m
//  Fit
//
//  Created by andrew on 28-05-15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

#import "Today.h"

@implementation Today

-(instancetype) initWithDate: (NSDate*) date
                        steps: (NSInteger) steps
               caloriesBurned: (NSInteger) caloriesBurned
                    heartRate: (NSInteger)heartRate
                 sleepMinutes: (NSInteger) sleepMinutes
                       height: (NSInteger)height
                       weight: (NSInteger)weight
                          age: (NSInteger)age;

{
    Today *day = [[[self class] alloc] init];
    day.date = date;
    day.steps = steps;
    day.caloriesBurned = caloriesBurned;
    day.heartRate = heartRate;
    day.sleepMinutes = sleepMinutes;
    day.height = height;
    day.weight = weight;
    day.age = age;
    
   
    return day;
}




@end
