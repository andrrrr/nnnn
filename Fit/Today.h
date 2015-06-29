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

@property NSDate* date;
@property NSInteger physicalFitnessScore;
@property NSString* userEmail;
@property NSInteger steps;
@property NSInteger caloriesBurned;
@property NSInteger heartRate;
@property NSInteger sleepMinutes;
@property NSInteger height;  //cm
@property NSInteger  weight;  //kg
@property NSInteger  age;    //years
@property NSInteger groupId;


//@property Person *owner;

-(instancetype) initWithDate:(NSDate*) date
        physicalFitnessScore:(NSInteger)physicalFitnessScore
                   userEmail:(NSString*) userEmail
                       steps:(NSInteger)steps
              caloriesBurned:(NSInteger)caloriesBurned
                   heartRate:(NSInteger)heartRate
                sleepMinutes:(NSInteger)sleepMinutes
                      height:(NSInteger)height
                      weight:(NSInteger)weight
                         age:(NSInteger)age
                     groupId:(NSInteger)groupId;



@end
