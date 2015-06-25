/*
    Copyright (C) 2015 IBM. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Displays age, height, and weight information retrieved from HealthKit.
*/

#import "AAPLProfileViewController.h"
#import "HKHealthStore+AAPLExtensions.h"
#import <GoogleOpenSource/GoogleOpenSource.h>

@import HealthKit;


// A mapping of logical sections of the table view to actual indexes.
typedef NS_ENUM(NSInteger, AAPLProfileViewControllerTableViewIndex) {
    AAPLProfileViewControllerTableViewIndexAge = 0,
    AAPLProfileViewControllerTableViewIndexHeight,
    AAPLProfileViewControllerTableViewIndexWeight
};

static NSString * const kClientId = @"528605303997-40kv5mb8qn5eog7e5klea0kcb3o3kp2a.apps.googleusercontent.com";


@implementation AAPLProfileViewController

int counterObservers;
bool allowNotif;
bool allowsSound;
bool allowsBadge;
bool allowsAlert;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setNotificationTypesAllowed];
    
    //fire this once a day
    [self scheduleNotification];
    
    if ([HKHealthStore isHealthDataAvailable]) {
        
        NSSet *writeDataTypes = [self dataTypesToWrite];
        NSSet *readDataTypes = [self dataTypesToRead];
        
        [self.healthStore requestAuthorizationToShareTypes:writeDataTypes readTypes:readDataTypes completion:^(BOOL success, NSError *error) {
            NSLog(@"---HEALTH KIT in completion block---");
            if (!success) {
                NSLog(@"You didn't allow HealthKit to access these read/write data types. In your app, try to handle this error gracefully when a user decides not to provide access. The error was: %@. If you're using a simulator, try it on a device.", error);
                
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // Update the user interface based on the current user's health information.
                counterObservers = 0;
                [self registerObservers];
                
                [self updateUsersAgeLabel];
                [self updateUsersHeightLabel];
                [self updateUsersWeightLabel];
                [self updateUsersStepsLabel];
                [self updateUsersSleepLabel];
                [self updateUsersHeartRateLabel];
                

            });
        }];
    }
    
//    GPPSignIn *signIn = [GPPSignIn sharedInstance];
//    signIn.shouldFetchGooglePlusUser = YES;
//    //signIn.shouldFetchGoogleUserEmail = YES;  // Uncomment to get the user's email
//    
//    // You previously set kClientId in the "Initialize the Google+ client" step
//    signIn.clientID = kClientId;
//    
//    // Uncomment one of these two statements for the scope you chose in the previous step
//    //signIn.scopes = @[ kGTLAuthScopePlusLogin ];  // "https://www.googleapis.com/auth/plus.login" scope
//    signIn.scopes = @[ @"profile" ];            // "profile" scope
//    
//    // Optional: declare signIn.actions, see "app activities"
//    signIn.delegate = self;
    
    
    [self cookBluemix];
}

//-(void)viewDidAppear:(BOOL)animated
//{
//    
//    [super viewDidAppear:animated];
//    
//    [self setNotificationTypesAllowed];
//    
//    //fire this once a day
//    [self scheduleNotification];
//    
//    if ([HKHealthStore isHealthDataAvailable]) {
//        
//        NSSet *writeDataTypes = [self dataTypesToWrite];
//        NSSet *readDataTypes = [self dataTypesToRead];
//        NSLog(@"---TTTTTT---");
//        
//        
//        [self.healthStore requestAuthorizationToShareTypes:writeDataTypes readTypes:readDataTypes completion:^(BOOL success, NSError *error) {
//            NSLog(@"---HEALTH KIT in completion block---");
//            
//            if (!success) {
//                NSLog(@"You didn't allow HealthKit to access these read/write data types. In your app, try to handle this error gracefully when a user decides not to provide access. The error was: %@. If you're using a simulator, try it on a device.", error);
//                
//                return;
//            }
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                // Update the user interface based on the current user's health information.
//                counterObservers = 0;
//                [self registerObservers];
//                [self updateUsersAgeLabel];
//                [self updateUsersHeightLabel];
//                [self updateUsersWeightLabel];
//                [self updateUsersStepsLabel];
//                [self updateUsersSleepLabel];
//                [self updateUsersHeartRateLabel];
//                
//            });
//        }];
//    }
//
//    [self cookBluemix];
//
//}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"******^^^^^^^^ From KVO");
    
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
    
    if(counterObservers == 6){[self calculateIndex]; }
}


- (void)registerObservers
{
    [self addObserver:self forKeyPath:@"stepsYesterday" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"ageYesterday" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"heightYesterday" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"weightYesterday" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"sleepMinutesYesterday" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"heartRateYesterday" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}


//- (void)finishedWithAuth: (GTMOAuth2Authentication *)auth error: (NSError *) error {
//    NSLog(@"Received error %@ and auth object %@",error, auth);
//}


- (void)setNotificationTypesAllowed
{
    NSLog(@"%s:", __PRETTY_FUNCTION__);
    // get the current notification settings
    UIUserNotificationSettings *currentSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    allowNotif = (currentSettings.types != UIUserNotificationTypeNone);
    allowsSound = (currentSettings.types & UIUserNotificationTypeSound) != 0;
    allowsBadge = (currentSettings.types & UIUserNotificationTypeBadge) != 0;
    allowsAlert = (currentSettings.types & UIUserNotificationTypeAlert) != 0;
}


- (void) cookBluemix
{
    //google login
    [[IMFGoogleAuthenticationHandler sharedInstance] registerWithDefaultDelegate];
    
    // initialize SDK with IBM Bluemix application ID and route
    IMFClient *imfClient = [IMFClient sharedInstance];
    [imfClient initializeWithBackendRoute:@"https://nn-personalized-insurance.eu-gb.mybluemix.net" backendGUID:@"d53c7135-a52e-433f-88b4-c1fd87f80436"];
    
    
    // Get reference to data manager
    IMFDataManager *manager = [IMFDataManager sharedInstance];
    
    // Create remote store
    [manager remoteStore:@"nndb" completionHandler:^(CDTStore *createdStore, NSError *error) {
        if(error){
            NSLog(@"Could not create remote store");
        }else{
            _remotedatastore = createdStore;
            NSLog(@"Successfully created store: %@", _remotedatastore.name);
            [_remotedatastore.mapper setDataType:@"Today" forClassName:NSStringFromClass([Today class])];
            [self createIndex: _remotedatastore];
        }
    }];
    
    // Set permissions for current user on a store
    [manager setCurrentUserPermissions: DB_ACCESS_GROUP_MEMBERS forStoreName: @"nndb" completionHander:^(BOOL success, NSError *error) {
        if(error){
            NSLog(@"Error: %@", error);
        }else{
            NSLog(@"Successfully updated permissions");
        }
    }];
}

- (void)createIndex:(CDTStore*)store {
    // The data type to use for the Automobile class
    NSString *dataType = [store.mapper dataTypeForClassName:NSStringFromClass([Today class])];
    
    // Create the index
    [store createIndexWithDataType:dataType fields:@[ @"steps", @"caloriesBurned", @"heartRate", @"sleepMinutes", @"height", @"weight", @"age"] completionHandler:^(NSError *error) {
        if(error){
            NSLog(@"error trying to create index in store");
        }else{
            NSLog(@"successfully created index in store");
        }
    }];
}

#pragma mark - HealthKit Permissions

// Returns the types of data that Fit wishes to write to HealthKit.
- (NSSet *)dataTypesToWrite {
    HKQuantityType *dietaryCalorieEnergyType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed];
    HKQuantityType *activeEnergyBurnType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
    HKQuantityType *heightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    HKQuantityType *weightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    HKQuantityType *distanceType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    HKQuantityType *stepsType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    HKQuantityType *heartRateType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    HKCategoryType *sleepType = [HKSampleType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    
    return [NSSet setWithObjects:dietaryCalorieEnergyType, activeEnergyBurnType, heightType, weightType, distanceType, stepsType, sleepType, heartRateType, nil];
}

// Returns the types of data that Fit wishes to read from HealthKit.
- (NSSet *)dataTypesToRead {
    HKQuantityType *dietaryCalorieEnergyType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed];
    HKQuantityType *activeEnergyBurnType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
    HKQuantityType *heightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    HKQuantityType *weightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    HKCharacteristicType *birthdayType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth];
    HKCharacteristicType *biologicalSexType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex];
    HKQuantityType *distanceType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    HKQuantityType *stepsType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    HKQuantityType *heartRateType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    HKCategoryType *sleepType = [HKSampleType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    
    
    //HKSampleType *sampleType = [HKSampleType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    
    return [NSSet setWithObjects:dietaryCalorieEnergyType, activeEnergyBurnType, heightType, weightType, birthdayType, biologicalSexType, distanceType, stepsType, sleepType, heartRateType, nil];
}

#pragma mark - Reading HealthKit Data

- (void)updateUsersAgeLabel {
    // Set the user's age unit (years).
    self.ageUnitLabel.text = NSLocalizedString(@"Age (yrs)", nil);
    
    NSError *error;
    NSDate *dateOfBirth = [self.healthStore dateOfBirthWithError:&error];
    
    if (!dateOfBirth) {
        NSLog(@"Either an error occured fetching the user's age information or none has been stored yet. In your app, try to handle this gracefully.");
        
        //return @"Not available";
        self.ageValueLabel.text = NSLocalizedString(@"Not available", nil);
    }
    else {
        // Compute the age of the user.
        NSDate *now = [NSDate date];
        
        NSDateComponents *ageComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:dateOfBirth toDate:now options:NSCalendarWrapComponents];
        
        NSUInteger usersAge = [ageComponents year];
        
       
        self.ageYesterday = usersAge;
        self.ageValueLabel.text = [NSNumberFormatter localizedStringFromNumber:@(usersAge) numberStyle:NSNumberFormatterNoStyle];
    }
}

- (void)updateUsersHeightLabel {
    // Fetch user's default height unit in meters.
    NSLengthFormatter *lengthFormatter = [[NSLengthFormatter alloc] init];
    lengthFormatter.unitStyle = NSFormattingUnitStyleLong;
    
    NSLengthFormatterUnit heightFormatterUnit = NSLengthFormatterUnitCentimeter;
    NSString *heightUnitString = [lengthFormatter unitStringFromValue:10 unit:heightFormatterUnit];
    NSString *localizedHeightUnitDescriptionFormat = NSLocalizedString(@"Height (%@)", nil);
    
    self.heightUnitLabel.text = [NSString stringWithFormat:localizedHeightUnitDescriptionFormat, heightUnitString];

    HKQuantityType *heightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
   
    // Query to get the user's latest height, if it exists.
    [self.healthStore aapl_mostRecentQuantitySampleOfType:heightType predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSError *error) {
        if (!mostRecentQuantity) {
            NSLog(@"Either an error occured fetching the user's height information or none has been stored yet. In your app, try to handle this gracefully.");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.heightValueLabel.text = NSLocalizedString(@"Not available", nil);
            });
            
        }
        else {
            // Determine the height in the required unit.
            
            HKUnit *heightUnit = [HKUnit meterUnitWithMetricPrefix:HKMetricPrefixCenti];
            double usersHeight = [mostRecentQuantity doubleValueForUnit:heightUnit];
            
           
            self.heightYesterday = usersHeight;

            
            
            // Update the user interface.
            dispatch_async(dispatch_get_main_queue(), ^{
                self.heightValueLabel.text = [NSNumberFormatter localizedStringFromNumber:@(usersHeight) numberStyle:NSNumberFormatterNoStyle];

            });
        }
    }];
}
    
    
- (void)updateUsersStepsLabel {
    
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
                                           
                                           float someFloat = ((float)value/(float)10000)*100;
                                           NSString *str = [NSString stringWithFormat:@"%i%%", (int)someFloat];
                                           
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               self.stepsPercentage.text = str;
                                               
                                               self.stepsYesterday = value;
                                               self.stepsValueLabel.text = [NSNumberFormatter localizedStringFromNumber:@(value) numberStyle:NSNumberFormatterNoStyle];
                                            });
                                       }
                                   }];
    };
    
    [self.healthStore executeQuery:query];

    self.stepsUnitLabel.text = [NSString stringWithFormat:@"Steps (yesterday)"];
}


- (void)updateUsersHeartRateLabel {
    HKQuantityType *heartRateType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    
    [self.healthStore aapl_mostRecentQuantitySampleOfType:heartRateType predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSError *error) {
        if (!mostRecentQuantity) {
            NSLog(@"Either an error occured fetching the user's heart rate information or none has been stored yet. In your app, try to handle this gracefully.");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.weightValueLabel.text = NSLocalizedString(@"Not available", nil);
            });
        }
        else {
            // Determine the weight in the required unit.
            HKUnit *heartRateUnit = [[HKUnit countUnit] unitDividedByUnit:[HKUnit minuteUnit]];
            double usersHR = [mostRecentQuantity doubleValueForUnit:heartRateUnit];
            
            //self.heartRateYesterday = usersHR;
            self.heartRateYesterday = (NSInteger)[NSNumberFormatter localizedStringFromNumber:@(usersHR) numberStyle:NSNumberFormatterNoStyle];
            
            float someFloat = ((float)usersHR/(float)60)*100;
            NSString *str = [NSString stringWithFormat:@"%i%%", (int)someFloat];
            if(someFloat > 100) {
                someFloat = 100 - (someFloat - 100);
            }
            
            // Update the user interface.
            dispatch_async(dispatch_get_main_queue(), ^{
                self.sleepPercentage.text = str;
                self.heartRateLabel.text = [NSNumberFormatter localizedStringFromNumber:@(usersHR) numberStyle:NSNumberFormatterNoStyle];
            });
        }
    }];
}


- (void)updateUsersWeightLabel {
    // Fetch the user's default weight unit in pounds.
    NSMassFormatter *massFormatter = [[NSMassFormatter alloc] init];
    massFormatter.unitStyle = NSFormattingUnitStyleLong;
    
    NSMassFormatterUnit weightFormatterUnit = NSMassFormatterUnitKilogram;
    NSString *weightUnitString = [massFormatter unitStringFromValue:10 unit:weightFormatterUnit];
    NSString *localizedWeightUnitDescriptionFormat = NSLocalizedString(@"Weight (%@)", nil);

    self.weightUnitLabel.text = [NSString stringWithFormat:localizedWeightUnitDescriptionFormat, weightUnitString];
    
    // Query to get the user's latest weight, if it exists.
    HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];

    [self.healthStore aapl_mostRecentQuantitySampleOfType:weightType predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSError *error) {
        if (!mostRecentQuantity) {
            NSLog(@"Either an error occured fetching the user's weight information or none has been stored yet. In your app, try to handle this gracefully.");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.weightValueLabel.text = NSLocalizedString(@"Not available", nil);
            });
        }
        else {
            // Determine the weight in the required unit.
            HKUnit *weightUnit = [HKUnit gramUnit];
            double usersWeight = [mostRecentQuantity doubleValueForUnit:weightUnit]/1000;
            
            
            self.weightYesterday = usersWeight;

            // Update the user interface.
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.weightValueLabel.text = [NSNumberFormatter localizedStringFromNumber:@(usersWeight) numberStyle:NSNumberFormatterNoStyle];
            });
        }
    }];
}


- (void)updateUsersSleepLabel {
    [self.healthStore hkQueryExecute: ^(double minutes, NSError *error) {
        if (minutes == 0) {
            NSLog(@"Either an error occured fetching the user's sleep information or none has been stored yet.");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.sleepDurationValueLabel.text = NSLocalizedString(@"Not available", nil);
            });
        }
        else {
            
            int hours = (int)minutes / 60;
            int minutesNew = (int)minutes - (hours*60);
            NSLog(@"hours slept: %ld:%ld", (long)hours, (long)minutesNew);
            
            
            self.sleepMinutesYesterday = minutes;
            float someFloat = ((float)minutes/(float)480)*100;
            NSString *str = [NSString stringWithFormat:@"%i%%", (int)someFloat];


            dispatch_async(dispatch_get_main_queue(), ^{
                self.sleepPercentage.text = str;
                self.sleepDurationValueLabel.text = [NSString stringWithFormat:@"%d:%d", hours, minutesNew] ;
            });
        }
    }];
}

- (void)scheduleNotification
{
    // New for iOS 8 - Register the notifications
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    if (notification)
    {
        NSDate *today =[NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        
        //for adding 3 minutes from now
//        NSDate *laterToday = [calendar dateByAddingUnit:NSCalendarUnitMinute
//                                                  value:3
//                                                 toDate:today
//                                                options:kNilOptions];
        
        
        
        NSCalendarOptions options = NSCalendarMatchNextTime;
        NSDate *nextNight = [calendar nextDateAfterDate:[NSDate date]
                                                matchingHour:16
                                                      minute:46
                                                      second:43
                                                     options:options];
        
        
        
        notification.fireDate = nextNight;
        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.applicationIconBadgeNumber = 1;
        notification.soundName = UILocalNotificationDefaultSoundName;
        notification.repeatInterval = NSCalendarUnitDay;
        
        if (allowsAlert)
        {
            notification.alertBody = @"Data was sent to the cloud";
        }
        if (allowsBadge)
        {
            notification.applicationIconBadgeNumber = 1;
        }
        if (allowsSound)
        {
            notification.soundName = UILocalNotificationDefaultSoundName;
        }
        
        
        // this will schedule the notification to fire at the fire date
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        
        // this will fire the notification right away, it will still also fire at the date we set
        //[[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        
        
        // we're creating a string of the date so we can log the time the notif is supposed to fire
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        [formatter setDateFormat:@"dd-MM-yyy hh:mm"];
        [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"CET"]];
        NSString *notifDate = [formatter stringFromDate:notification.fireDate];
        NSLog(@"%s: fire time = %@", __PRETTY_FUNCTION__, notifDate);
    }
}


#pragma mark - Writing HealthKit Data

- (void)saveHeightIntoHealthStore:(double)height {
    // Save the user's height into HealthKit.
    HKUnit *meterUnit = [HKUnit meterUnit];
    HKQuantity *heightQuantity = [HKQuantity quantityWithUnit:meterUnit doubleValue:height];

    HKQuantityType *heightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    NSDate *now = [NSDate date];
    
    HKQuantitySample *heightSample = [HKQuantitySample quantitySampleWithType:heightType quantity:heightQuantity startDate:now endDate:now];
    
    [self.healthStore saveObject:heightSample withCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"An error occured saving the height sample %@. In your app, try to handle this gracefully. The error was: %@.", heightSample, error);
            abort();
        }

        [self updateUsersHeightLabel];
    }];
}

- (void)saveWeightIntoHealthStore:(double)weight {
    // Save the user's weight into HealthKit.
    HKUnit *poundUnit = [HKUnit poundUnit];
    HKQuantity *weightQuantity = [HKQuantity quantityWithUnit:poundUnit doubleValue:weight];

    HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    NSDate *now = [NSDate date];
    
    HKQuantitySample *weightSample = [HKQuantitySample quantitySampleWithType:weightType quantity:weightQuantity startDate:now endDate:now];
    
    [self.healthStore saveObject:weightSample withCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"An error occured saving the weight sample %@. In your app, try to handle this gracefully. The error was: %@.", weightSample, error);
            abort();
        }

        [self updateUsersWeightLabel];
    }];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AAPLProfileViewControllerTableViewIndex index = (AAPLProfileViewControllerTableViewIndex)indexPath.row;
    
    // We won't allow people to change their date of birth, so ignore selection of the age cell.
    if (index == AAPLProfileViewControllerTableViewIndexAge) {
        return;
    }
    
    // Set up variables based on what row the user has selected.
    NSString *title;
    void (^valueChangedHandler)(double value);
    
    if (index == AAPLProfileViewControllerTableViewIndexHeight) {
        title = NSLocalizedString(@"Your Height", nil);

        valueChangedHandler = ^(double value) {
            [self saveHeightIntoHealthStore:value];
        };
    }
    else if (index == AAPLProfileViewControllerTableViewIndexWeight) {
        title = NSLocalizedString(@"Your Weight", nil);
        
        valueChangedHandler = ^(double value) {
            [self saveWeightIntoHealthStore:value];
        };
    }
    
    // Create an alert controller to present.
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    // Add the text field to let the user enter a numeric value.
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        // Only allow the user to enter a valid number.
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];
    
    // Create the "OK" button.
    NSString *okTitle = NSLocalizedString(@"OK", nil);
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textField = alertController.textFields.firstObject;
        
        double value = textField.text.doubleValue;
        
        valueChangedHandler(value);
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }];

    [alertController addAction:okAction];
    
    // Create the "Cancel" button.
    NSString *cancelTitle = NSLocalizedString(@"Cancel", nil);
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }];

    [alertController addAction:cancelAction];
    
    // Present the alert controller.
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Convenience

- (NSNumberFormatter *)numberFormatter {
    static NSNumberFormatter *numberFormatter;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        numberFormatter = [[NSNumberFormatter alloc] init];
    });
    
    return numberFormatter;
}


- (void) saveDataToDb {
    CDTStore *store = _remotedatastore;
    
    
    [self getYesterday:^(Today *today) {
        if(today){
            [store save:today completionHandler:^(id savedObject, NSError *error) {
                if (error) {
                    NSLog(@"Error trying to save object to the cloud: %@", error);
                } else {
                    // use the result
                    Today *savedToday = savedObject;
                    NSLog(@"saved revision: %@", savedToday);
                }
            }];
        }
    }];
}

typedef void(^myCompletion)(Today *today);

- (void)getYesterday:(myCompletion) compblock {
    
    __block Today *today;
    
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_async(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        [self updateUsersStepsLabel];
        [self updateUsersAgeLabel];
        [self updateUsersSleepLabel];
        [self updateUsersHeightLabel];
        [self updateUsersWeightLabel];
        
        

    });
    

    
    dispatch_group_notify(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        
        
        [NSThread sleepForTimeInterval:8.0];
        
        NSLog(@"### stepsYest, %ld", (long)self.stepsYesterday);
        NSLog(@"### ageYest, %ld", (long)self.ageYesterday);
        NSLog(@"### heightYesterday, %ld", (long)self.heightYesterday);
        NSLog(@"### weightYesterday, %ld", (long)self.weightYesterday);
        NSLog(@"### sleepMinutesYesterday, %ld", (long)self.sleepMinutesYesterday);
        
        NSDate *todayDate =[NSDate date];
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDateComponents *components = [[NSDateComponents alloc] init];
        [components setDay:-1];
        NSDate *yesterday = [cal dateByAddingComponents:components toDate:todayDate options:0];
        
        
        today = [[Today alloc] initWithDate:yesterday steps:self.stepsYesterday caloriesBurned:self.caloriesBurnedYesterday heartRate:self.heartRateYesterday sleepMinutes:self.sleepMinutesYesterday height:self.heightYesterday weight:self.weightYesterday age:self.ageYesterday ];
        compblock(today);
    });
}


- (void)calculateIndex {
    int scoreMovement;
    int scoreSleep;
    int scoreHeartRate;
    
    double physicalFitnessScore;
    
    NSLog(@"### stepsYest, %ld", (long)self.stepsYesterday);
    NSLog(@"### ageYest, %ld", (long)self.ageYesterday);
    NSLog(@"### heightYesterday, %ld", (long)self.heightYesterday);
    NSLog(@"### weightYesterday, %ld", (long)self.weightYesterday);
    NSLog(@"### sleepMinutesYesterday, %ld", (long)self.sleepMinutesYesterday);
    NSLog(@"### heartRateYesterday, %ld", (long)self.heartRateYesterday);
    
    //calculate score movement
    if (self.stepsYesterday < 3000) scoreMovement = 0;
    else if (self.stepsYesterday >= 3000 && self.stepsYesterday < 7500) scoreMovement = 1;
    else if (self.stepsYesterday >= 7500 && self.stepsYesterday < 10000) scoreMovement = 2;
    else if (self.stepsYesterday >= 10000 && self.stepsYesterday < 15000) scoreMovement = 3;
    else if (self.stepsYesterday >= 15000 && self.stepsYesterday < 17500)
    {
        scoreMovement = 2;
        [self presentWarningWithText:@"You have walked more than 15000 steps today, this is too much. Slow down a bit?"];
    }
    else if (self.stepsYesterday >= 17500 && self.stepsYesterday < 20000)
    {
        scoreMovement = 1;
        [self presentWarningWithText:@"You have walked more than 17500 steps today, this is too much. Slow down a bit?"];
    }
    else if (self.stepsYesterday > 20000)
    {
        scoreMovement = 0;
        [self presentWarningWithText:@"You have walked more than 20000 steps today, this is too much. Slow down a bit?"];
    }

    
    //calculate score sleep
    if (self.sleepMinutesYesterday < 360 || self.sleepMinutesYesterday > 600) scoreSleep = 0;
    else if ((self.sleepMinutesYesterday >=360 && self.sleepMinutesYesterday <420) || (self.sleepMinutesYesterday >=540 && self.sleepMinutesYesterday <600)) scoreSleep = 1;
    else if ((self.sleepMinutesYesterday >=420 && self.sleepMinutesYesterday <450) || (self.sleepMinutesYesterday >=510 && self.sleepMinutesYesterday <540)) scoreSleep = 2;
    else if (self.sleepMinutesYesterday >= 450 || self.sleepMinutesYesterday < 510) scoreSleep = 3;

    
    //calculate score heart rate
    if(self.heartRateYesterday<=39 || self.heartRateYesterday>=100 )scoreHeartRate = 0;
    else if(self.heartRateYesterday>=40 || self.heartRateYesterday<=49 )scoreHeartRate = 3;
    else if(self.heartRateYesterday>=50 || self.heartRateYesterday<=59 )scoreHeartRate = 2;
    else if(self.heartRateYesterday>=60 || self.heartRateYesterday<=99 )scoreHeartRate = 1;
    
    NSLog(@"scoreMOVEMENT  %d", scoreMovement);
    NSLog(@"scoreSLEEP  %d", scoreSleep);
    NSLog(@"scoreHR  %d", scoreHeartRate);
    physicalFitnessScore = (scoreMovement*0.55 + scoreSleep*0.2 + scoreHeartRate*0.25)*100;
    NSLog(@"physicalFitnessScore  %f", physicalFitnessScore);
    
    self.indexLabel.text = [NSNumberFormatter localizedStringFromNumber:@(physicalFitnessScore) numberStyle:NSNumberFormatterDecimalStyle];
}

-(void)presentWarningWithText:(NSString*)msgText {
    // New for iOS 8 - Register the notifications
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    if (notification)
    {
        notification.applicationIconBadgeNumber = 1;
        notification.soundName = UILocalNotificationDefaultSoundName;
        notification.repeatInterval = NSCalendarUnitDay;
        
        if (allowsAlert)
        {
            notification.alertBody = msgText;
        }
        if (allowsBadge)
        {
            notification.applicationIconBadgeNumber = 1;
        }
        if (allowsSound)
        {
            notification.soundName = UILocalNotificationDefaultSoundName;
        }
        
        
        // this will fire the notification right away, it will still also fire at the date we set
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
}

+ (AAPLProfileViewController *)sharedInstanceOfMe
{
    static AAPLProfileViewController *sharedInstanceOfMe = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstanceOfMe = [[AAPLProfileViewController alloc] init];
    });
    return sharedInstanceOfMe;
}

- (IBAction)sendData:(id)sender {
    [self saveDataToDb];
}


@end