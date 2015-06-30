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
        
        self.healthStore = [[HKHealthStore alloc] init];
        self.healthKit = [[healthKit alloc] init];
        
        [self.healthStore requestAuthorizationToShareTypes:writeDataTypes readTypes:readDataTypes completion:^(BOOL success, NSError *error) {
            NSLog(@"---HEALTH KIT in completion block---");
            if (!success) {
                NSLog(@"You didn't allow HealthKit to access these read/write data types. In your app, try to handle this error gracefully when a user decides not to provide access. The error was: %@. If you're using a simulator, try it on a device.", error);
                
                return;
            }
            
            //[self.healthKit getCaloriesBurned];
            
            dispatch_async(dispatch_get_main_queue(), ^{
        
                [self registerObserversAndCalculateIndex];
                
                [self getUserCaloriesBurned];
                
                [self updateUsersAgeLabel];
                [self updateUsersHeightLabel];
                [self updateUsersWeightLabel];
                [self updateUsersStepsLabel];
                [self updateUsersSleepLabel];
                [self updateUsersHeartRateLabel];
                

            });
        }];
    }
    
    
    [self cookBluemix];
}

-(void)viewDidAppear:(BOOL)animated {
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
}

- (IBAction)swapButtonPressed:(id)sender
{
    NSLog(@"swap button pressed");
    [self.containerViewController swapViewControllers];
    //[self.testerViewController redrawGraph];
}

- (void)swapFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController {
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"embedContainer"]) {
        
        self.containerViewController = segue.destinationViewController;
       
    }
}





-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{

    
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
    
    if(counterObservers == 7){
        [self calculateIndex];
        
    }
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




- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error {
    NSLog(@"Received Error %@ and auth object==%@", error, auth);
    
    if (error) {
        NSLog(@"ERROR: google authentication %@", error);
    } else {
        //[self refreshInterfaceBasedOnSignIn];
        
        GTLQueryPlus *query = [GTLQueryPlus queryForPeopleGetWithUserId:@"me"];
        
        NSLog(@"email %@ ", [NSString stringWithFormat:@"Email: %@",[GPPSignIn sharedInstance].authentication.userEmail]);
        NSLog(@"Received error %@ and auth object %@",error, auth);
        
        // 1. Create a |GTLServicePlus| instance to send a request to Google+.
        GTLServicePlus* plusService = [[GTLServicePlus alloc] init] ;
        plusService.retryEnabled = YES;
        
        // 2. Set a valid |GTMOAuth2Authentication| object as the authorizer.
        [plusService setAuthorizer:[GPPSignIn sharedInstance].authentication];
        
        // 3. Use the "v1" version of the Google+ API.*
        plusService.apiVersion = @"v1";
        [plusService executeQuery:query
                completionHandler:^(GTLServiceTicket *ticket,
                                    GTLPlusPerson *person,
                                    NSError *error) {
                    if (error) {
                        //Handle Error
                    } else {
                        NSLog(@"Email= %@", [GPPSignIn sharedInstance].authentication.userEmail);
                        NSLog(@"GoogleID=%@", person.identifier);
                        NSLog(@"User Name=%@", [person.name.givenName stringByAppendingFormat:@" %@", person.name.familyName]);
                        NSLog(@"Gender=%@", person.gender);
                    }
                }];
    }
}



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
    [store createIndexWithDataType:dataType fields:@[ @"date", @"userEmail", @"steps", @"caloriesBurned", @"heartRate", @"sleepMinutes", @"height", @"weight", @"age", @"groupId" ] completionHandler:^(NSError *error) {
        if(error){
            NSLog(@"error trying to create index in store, %@", error);
        }else{
            NSLog(@"successfully created index in store");
        }
    }];
}



#pragma mark - HealthKit Permissions

// Returns the types of data that Fit wishes to write to HealthKit.
- (NSSet *)dataTypesToWrite {
//    HKQuantityType *dietaryCalorieEnergyType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed];
//    HKQuantityType *activeEnergyBurnType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
//    HKQuantityType *heightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
//    HKQuantityType *weightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
//    HKQuantityType *distanceType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
//    HKQuantityType *stepsType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
//    HKQuantityType *heartRateType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
//    HKCategoryType *sleepType = [HKSampleType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    
//    return [NSSet setWithObjects:dietaryCalorieEnergyType, activeEnergyBurnType, heightType, weightType, distanceType, stepsType, sleepType, heartRateType, nil];
    
    
    return [NSSet setWithObjects:nil];
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

    [self.healthStore getUsersAge:^(double usersAge, NSError *error) {
        NSString *inStr = [NSString stringWithFormat: @"%ld years", (long)usersAge];
        self.ageYesterday = usersAge;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.ageValueLabel.text = inStr;
        });
    }];
    

}

- (void)updateUsersHeightLabel {
    
    [self.healthStore getUsersHeight:^(double height, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.heightYesterday = height;
            self.heightValueLabel.text = [NSNumberFormatter localizedStringFromNumber:@(height) numberStyle:NSNumberFormatterNoStyle];
            
        });
    }];
}

- (void)updateUsersStepsLabel {
    [self.healthStore getUsersSteps:^(double steps, NSError *error) {
        float someFloat = ((float)steps/(float)10000)*100;
        NSString *str = [NSString stringWithFormat:@"%i%%", (int)someFloat];
        self.stepsYesterday = steps;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.stepsPercentage.text = str;
            self.stepsValueLabel.text = [NSNumberFormatter localizedStringFromNumber:@(steps) numberStyle:NSNumberFormatterNoStyle];
            
        });
    }];
    
}


- (void)updateUsersHeartRateLabel {
    [self.healthStore getUsersHeartRate:^(double beats, NSError *error) {
        float someFloat = ((float)beats/(float)60)*100;
        //NSString *str = [NSString stringWithFormat:@"%i%%", (int)someFloat];
        if(someFloat > 200){
            someFloat = 300 - someFloat;
        }
        else if(someFloat > 100) {
            someFloat = 200 - someFloat;
        }
        self.heartRateYesterday = beats;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.heartPercentage.text = [NSString stringWithFormat:@"%i%%", (int)someFloat];
            self.heartRateLabel.text = [NSNumberFormatter localizedStringFromNumber:@(beats) numberStyle:NSNumberFormatterNoStyle];
            
        });
    }];


}


- (void)updateUsersWeightLabel {
    
    [self.healthStore getUsersWeight:^(double kilos, NSError *error) {
        self.weightYesterday = kilos;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.self.weightValueLabel.text = [NSNumberFormatter localizedStringFromNumber:@(kilos) numberStyle:NSNumberFormatterNoStyle];
            
        });
    }];



}


- (void)updateUsersSleepLabel {
    [self.healthStore getUsersSleep: ^(double minutes, NSError *error) {
        if (minutes == 0) {
            NSLog(@"Either an error occured fetching the user's sleep information or none has been stored yet.");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.sleepDurationValueLabel.text = NSLocalizedString(@"NA", nil);
            });
        }
        else {
            self.sleepPercentage.text = @"";
            int hours = (int)(minutes / 60);
            int minutesNew = (int)minutes - (hours*60);
            
            self.sleepMinutesYesterday = minutes;
            float someFloat1 = ((float)minutes/(float)480)*100;


            dispatch_async(dispatch_get_main_queue(), ^{
                self.sleepPercentage.text = [NSString stringWithFormat:@"%d%%", (int)someFloat1];
                self.sleepDurationValueLabel.text = [NSString stringWithFormat:@"%d:%d", hours, minutesNew];
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
        //NSDate *today =[NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        
        //for adding 3 minutes from now
//        NSDate *laterToday = [calendar dateByAddingUnit:NSCalendarUnitMinute
//                                                  value:3
//                                                 toDate:today
//                                                options:kNilOptions];
        
        
        
        NSCalendarOptions options = NSCalendarMatchNextTime;
        NSDate *nextNight = [calendar nextDateAfterDate:[NSDate date]
                                                matchingHour:11
                                                      minute:25
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

-(void)getUserCaloriesBurned
{
    [self.healthStore getUsersEnergyBurned: ^(double activeEnergyBurned, NSError *error) {
        self.caloriesBurnedYesterday = activeEnergyBurned;
        
        self.caloriesBurnedYesterday = (double)activeEnergyBurned * (double)0.239005736;
    }];
    
}



#pragma mark - Writing HealthKit Data

//- (void)saveHeightIntoHealthStore:(double)height {
//    // Save the user's height into HealthKit.
//    HKUnit *meterUnit = [HKUnit meterUnit];
//    HKQuantity *heightQuantity = [HKQuantity quantityWithUnit:meterUnit doubleValue:height];
//
//    HKQuantityType *heightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
//    NSDate *now = [NSDate date];
//    
//    HKQuantitySample *heightSample = [HKQuantitySample quantitySampleWithType:heightType quantity:heightQuantity startDate:now endDate:now];
//    
//    [self.healthStore saveObject:heightSample withCompletion:^(BOOL success, NSError *error) {
//        if (!success) {
//            NSLog(@"An error occured saving the height sample %@. In your app, try to handle this gracefully. The error was: %@.", heightSample, error);
//            abort();
//        }
//
//        [self updateUsersHeightLabel];
//    }];
//}
//
//- (void)saveWeightIntoHealthStore:(double)weight {
//    // Save the user's weight into HealthKit.
//    HKUnit *poundUnit = [HKUnit poundUnit];
//    HKQuantity *weightQuantity = [HKQuantity quantityWithUnit:poundUnit doubleValue:weight];
//
//    HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
//    NSDate *now = [NSDate date];
//    
//    HKQuantitySample *weightSample = [HKQuantitySample quantitySampleWithType:weightType quantity:weightQuantity startDate:now endDate:now];
//    
//    [self.healthStore saveObject:weightSample withCompletion:^(BOOL success, NSError *error) {
//        if (!success) {
//            NSLog(@"An error occured saving the weight sample %@. In your app, try to handle this gracefully. The error was: %@.", weightSample, error);
//            abort();
//        }
//
//        [self updateUsersWeightLabel];
//    }];
//}

#pragma mark - UITableViewDelegate

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    AAPLProfileViewControllerTableViewIndex index = (AAPLProfileViewControllerTableViewIndex)indexPath.row;
//    
//    // We won't allow people to change their date of birth, so ignore selection of the age cell.
//    if (index == AAPLProfileViewControllerTableViewIndexAge) {
//        return;
//    }
//    
//    // Set up variables based on what row the user has selected.
//    NSString *title;
//    void (^valueChangedHandler)(double value);
//    
//    if (index == AAPLProfileViewControllerTableViewIndexHeight) {
//        title = NSLocalizedString(@"Your Height", nil);
//
//        valueChangedHandler = ^(double value) {
//            [self saveHeightIntoHealthStore:value];
//        };
//    }
//    else if (index == AAPLProfileViewControllerTableViewIndexWeight) {
//        title = NSLocalizedString(@"Your Weight", nil);
//        
//        valueChangedHandler = ^(double value) {
//            [self saveWeightIntoHealthStore:value];
//        };
//    }
//    
//    // Create an alert controller to present.
//    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
//    
//    // Add the text field to let the user enter a numeric value.
//    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
//        // Only allow the user to enter a valid number.
//        textField.keyboardType = UIKeyboardTypeDecimalPad;
//    }];
//    
//    // Create the "OK" button.
//    NSString *okTitle = NSLocalizedString(@"OK", nil);
//    UIAlertAction *okAction = [UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//        UITextField *textField = alertController.textFields.firstObject;
//        
//        double value = textField.text.doubleValue;
//        
//        valueChangedHandler(value);
//        
//        [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    }];
//
//    [alertController addAction:okAction];
//    
//    // Create the "Cancel" button.
//    NSString *cancelTitle = NSLocalizedString(@"Cancel", nil);
//    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
//        [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    }];
//
//    [alertController addAction:cancelAction];
//    
//    // Present the alert controller.
//    [self presentViewController:alertController animated:YES completion:nil];
//}

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


//- (void) saveDataWithInputDay:(Today*) today{
//    CDTStore *store = _remotedatastore;
//    
//    
//        [store save:today completionHandler:^(id savedObject, NSError *error) {
//        if (error) {
//            NSLog(@"Error trying to save object to the cloud: %@", error);
//        } else {
//            // use the result
//            Today *savedToday = savedObject;
//            NSLog(@"saved revision: %@", savedToday);
//        }
//            
//    }];
//}



typedef void(^myCompletion)(Today *today);

- (void)getYesterday:(myCompletion) compblock {
    
   // __block Today *today;
    
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_async(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        
        
        [self registerObserversAndCalculateIndex];
        
        [self getUserCaloriesBurned];
        
        [self updateUsersAgeLabel];
        [self updateUsersHeightLabel];
        [self updateUsersWeightLabel];
        [self updateUsersStepsLabel];
        [self updateUsersSleepLabel];
        [self updateUsersHeartRateLabel];
        
    });
    

    
    dispatch_group_notify(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        
        NSLog(@"### physicalFitnessScoreYesterday, %ld", (long)self.physicalFitnessScoreYesterday);
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
        
        GPPSignIn *signIn = [GPPSignIn sharedInstance];
        //signIn.userEmail
        
        Today *today = [[Today alloc] initWithDate:yesterday physicalFitnessScore:self.physicalFitnessScoreYesterday userEmail:signIn.userEmail steps:self.stepsYesterday caloriesBurned:self.caloriesBurnedYesterday heartRate:self.heartRateYesterday sleepMinutes:self.sleepMinutesYesterday height:self.heightYesterday weight:self.weightYesterday age:self.ageYesterday groupId:self.groupIdYesterday];
        
        compblock(today);
    });
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.indexLabel.text = [NSNumberFormatter localizedStringFromNumber:@(physicalFitnessScore) numberStyle:NSNumberFormatterDecimalStyle];
        
    });
    
    
    self.BMIlabel.text = @"";
    double BMI = 0;
    if(self.heightYesterday!=0){
        BMI = 100*100*(double)self.weightYesterday/((double)self.heightYesterday*(double)self.heightYesterday);
        NSLog(@"BMI: %f", BMI);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.BMIlabel.text = [NSNumberFormatter localizedStringFromNumber:@(BMI) numberStyle:NSNumberFormatterNoStyle];
     });
   
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

- (Today *)sharedInstanceOfToday
{
    static AAPLProfileViewController *sharedInstanceOfMe = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstanceOfMe = [[AAPLProfileViewController alloc] init];
    });
    return sharedInstanceOfMe;

    
    
//    NSDate *todayDate =[NSDate date];
//    NSCalendar *cal = [NSCalendar currentCalendar];
//    NSDateComponents *components = [[NSDateComponents alloc] init];
//    [components setDay:-1];
//    NSDate *yesterday = [cal dateByAddingComponents:components toDate:todayDate options:0];
//
//    
//    
//    static Today *sharedInstanceOfToday = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        sharedInstanceOfToday = [[Today alloc] initWithDate:yesterday physicalFitnessScore:self.physicalFitnessScoreYesterday userEmail:@"" steps:self.stepsYesterday caloriesBurned:self.caloriesBurnedYesterday heartRate:self.heartRateYesterday sleepMinutes:self.sleepMinutesYesterday height:self.heightYesterday weight:self.weightYesterday age:self.ageYesterday groupId:self.groupIdYesterday];
//    });
//    return sharedInstanceOfToday;
    
  
}

- (IBAction)sendData:(id)sender {
    [self saveDataToDb];
}


@end