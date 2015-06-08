//
//  Today.m
//  Fit
//
//  Created by andrew on 28-05-15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

#import "Today.h"

@implementation Today

-(instancetype) initWithId: (NSInteger) idid steps: (NSInteger) steps caloriesBurned: (NSInteger) caloriesBurned caloriesEaten: (NSInteger) caloriesEaten sleepHours:(double) sleepHours
{
    Today *day = [[[self class] alloc] init];
    day.id = idid;
    day.steps = steps;
    day.caloriesBurned = caloriesBurned;
    day.caloriesEaten = caloriesEaten;
    day.sleepHours = sleepHours;
    return day;
}




@end
