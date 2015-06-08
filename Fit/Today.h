//
//  Today.h
//  Fit
//
//  Created by andrew on 28-05-15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CloudantToolkit/CloudantToolkit.h>
#import <CloudantSync.h>
#import <IMFData/IMFData.h>

@interface Today : NSObject<CDTDataObject>

@property (strong, nonatomic, readwrite) CDTDataObjectMetadata *metadata;

@property NSInteger id;
@property NSInteger steps;
@property NSInteger caloriesBurned;
@property NSInteger caloriesEaten;
@property double sleepHours;
//@property Person *owner;

-(instancetype) initWithId: (NSInteger) id steps: (NSInteger) steps caloriesBurned: (NSInteger) caloriesBurned caloriesEaten: (NSInteger) caloriesEaten sleepHours:(double) sleepHours;

@end
