/*
    Copyright (C) 2015 IBM. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Displays age, height, and weight information retrieved from HealthKit.
*/

#import "AAPLProfileViewController.h"
#import "HKHealthStore+AAPLExtensions.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <GoogleOpenSource/GoogleOpenSource.h>


// A mapping of logical sections of the table view to actual indexes.
typedef NS_ENUM(NSInteger, AAPLProfileViewControllerTableViewIndex) {
    AAPLProfileViewControllerTableViewIndexAge = 0,
    AAPLProfileViewControllerTableViewIndexHeight,
    AAPLProfileViewControllerTableViewIndexWeight
};

static NSString * const kClientId = @"528605303997-40kv5mb8qn5eog7e5klea0kcb3o3kp2a.apps.googleusercontent.com";

@interface AAPLProfileViewController ()

// Note that the user's age is not editable.
@property (nonatomic, weak) IBOutlet UILabel *ageUnitLabel;
@property (nonatomic, weak) IBOutlet UILabel *ageValueLabel;

@property (nonatomic, weak) IBOutlet UILabel *heightValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *heightUnitLabel;

@property (nonatomic, weak) IBOutlet UILabel *weightValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *weightUnitLabel;

@property (nonatomic, weak) IBOutlet UILabel *stepsValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *stepsUnitLabel;

@property (strong, nonatomic) IBOutlet UILabel *sleepDurationLabel;
@property (strong, nonatomic) IBOutlet UILabel *sleepDurationValueLabel;

@property CDTStore *remotedatastore;

@end


@implementation AAPLProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] init];
//    loginButton.center = self.view.center;
//    [self.view addSubview:loginButton];
    
    
    GPPSignIn *signIn = [GPPSignIn sharedInstance];
    signIn.shouldFetchGooglePlusUser = YES;
    //signIn.shouldFetchGoogleUserEmail = YES;  // Uncomment to get the user's email
    
    // You previously set kClientId in the "Initialize the Google+ client" step
    signIn.clientID = kClientId;
    
    // Uncomment one of these two statements for the scope you chose in the previous step
    //signIn.scopes = @[ kGTLAuthScopePlusLogin ];  // "https://www.googleapis.com/auth/plus.login" scope
    signIn.scopes = @[ @"profile" ];            // "profile" scope
    
    // Optional: declare signIn.actions, see "app activities"
    signIn.delegate = self;
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // Set up an HKHealthStore, asking the user for read/write permissions. The profile view controller is the
    // first view controller that's shown to the user, so we'll ask for all of the desired HealthKit permissions now.
    // In your own app, you should consider requesting permissions the first time a user wants to interact with
    // HealthKit data.
    if ([HKHealthStore isHealthDataAvailable]) {
        NSSet *writeDataTypes = [self dataTypesToWrite];
        NSSet *readDataTypes = [self dataTypesToRead];
        
        [self.healthStore requestAuthorizationToShareTypes:writeDataTypes readTypes:readDataTypes completion:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"You didn't allow HealthKit to access these read/write data types. In your app, try to handle this error gracefully when a user decides not to provide access. The error was: %@. If you're using a simulator, try it on a device.", error);
                
                return;
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                // Update the user interface based on the current user's health information.
                [self updateUsersAgeLabel];
                [self updateUsersHeightLabel];
                [self updateUsersWeightLabel];
                [self updateUsersStepsLabel];
                
                self.sleepDurationValueLabel.text = @"8,3";
                //[self updateUsersSleepLabel];
            });
        }];
    }
    [self cookBluemix];
}



- (void)finishedWithAuth: (GTMOAuth2Authentication *)auth error: (NSError *) error {
    NSLog(@"Received error %@ and auth object %@",error, auth);
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
    [store createIndexWithDataType:dataType fields:@[@"id", @"steps", @"caloriesBurned", @"caloriesEaten", @"sleepHours"] completionHandler:^(NSError *error) {
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
    HKQuantityType *sleepType = [HKSampleType quantityTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    
    return [NSSet setWithObjects:dietaryCalorieEnergyType, activeEnergyBurnType, heightType, weightType, distanceType, stepsType, sleepType, nil];
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
    HKQuantityType *sleepType = [HKSampleType quantityTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    
    return [NSSet setWithObjects:dietaryCalorieEnergyType, activeEnergyBurnType, heightType, weightType, birthdayType, biologicalSexType, distanceType, stepsType, sleepType, nil];
}

#pragma mark - Reading HealthKit Data

- (void)updateUsersAgeLabel {
    // Set the user's age unit (years).
    self.ageUnitLabel.text = NSLocalizedString(@"Age (yrs)", nil);
    
    NSError *error;
    NSDate *dateOfBirth = [self.healthStore dateOfBirthWithError:&error];
    
    if (!dateOfBirth) {
        NSLog(@"Either an error occured fetching the user's age information or none has been stored yet. In your app, try to handle this gracefully.");
        
        self.ageValueLabel.text = NSLocalizedString(@"Not available", nil);
    }
    else {
        // Compute the age of the user.
        NSDate *now = [NSDate date];
        
        NSDateComponents *ageComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:dateOfBirth toDate:now options:NSCalendarWrapComponents];
        
        NSUInteger usersAge = [ageComponents year];

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
            // HKUnit *heightUnit = [HKUnit centimeterUnit];
            HKUnit *heightUnit = [HKUnit meterUnitWithMetricPrefix:HKMetricPrefixCenti];
            double usersHeight = [mostRecentQuantity doubleValueForUnit:heightUnit];
            
            // Update the user interface.
            dispatch_async(dispatch_get_main_queue(), ^{
                self.heightValueLabel.text = [NSNumberFormatter localizedStringFromNumber:@(usersHeight) numberStyle:NSNumberFormatterNoStyle];
            });
        }
    }];
}
    
    
- (void)updateUsersStepsLabel {
    
//this also works!!!
    
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
                                                 value:-7
                                                toDate:endDate
                                               options:0];
        
        // Plot the daily step counts over the past 7 days
        [results enumerateStatisticsFromDate:startDate
                                      toDate:endDate
                                   withBlock:^(HKStatistics *result, BOOL *stop) {
                                       
                                       HKQuantity *quantity = result.sumQuantity;
                                       if (quantity) {
                                           NSDate *date = result.startDate;
                                           double value = [quantity doubleValueForUnit:[HKUnit countUnit]];
                                           NSLog(@"%@: %f", date, value);
                                           self.stepsValueLabel.text = [NSNumberFormatter localizedStringFromNumber:@(value) numberStyle:NSNumberFormatterNoStyle];
                                       }
                                   }];
    };
    
    [self.healthStore executeQuery:query];

    self.stepsUnitLabel.text = [NSString stringWithFormat:@"Steps"];
    
    
    
    // check the latest method
//    HKQuantityType *stepsType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
//    
//    [self.healthStore aapl_mostRecentQuantitySampleOfType:stepsType predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSError *error) {
//        if (!mostRecentQuantity) {
//            NSLog(@"Either an error occured fetching the user's weight information or none has been stored yet. In your app, try to handle this gracefully.");
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                self.stepsValueLabel.text = NSLocalizedString(@"Not available", nil);
//            });
//        }
//        else {
//            
//            HKUnit *stepsUnit = [HKUnit countUnit];
//            double usersSteps = [mostRecentQuantity doubleValueForUnit:stepsUnit];
//            
//            // Update the user interface.
//            dispatch_async(dispatch_get_main_queue(), ^{
//                self.stepsValueLabel.text = [NSNumberFormatter localizedStringFromNumber:@(usersSteps) numberStyle:NSNumberFormatterNoStyle];
//            });
//        }
//    }];
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

            // Update the user interface.
            dispatch_async(dispatch_get_main_queue(), ^{
                self.weightValueLabel.text = [NSNumberFormatter localizedStringFromNumber:@(usersWeight) numberStyle:NSNumberFormatterNoStyle];
            });
        }
    }];
}



- (void)updateUsersSleepLabel {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *endDate = [NSDate date];
    NSDate *startDate = [calendar dateByAddingUnit:NSCalendarUnitDay
                                                     value:-1
                                                    toDate:endDate
                                                   options:0];

    
    
    HKCategoryType *categoryType =
    [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    
    HKCategorySample *categorySample =
    [HKCategorySample categorySampleWithType:categoryType
                                       value:HKCategoryValueSleepAnalysisAsleep
                                   startDate:startDate
                                     endDate:endDate];
    NSLog(@"category sample: %@", categorySample);

    
    self.sleepDurationValueLabel.text = @"8,3";
    
    // Query to get the user's latest weight, if it exists.
//    HKQuantityType *sleepDurationType = [HKQuantityType quantityTypeForIdentifier:HKCategoryValueSleepAnalysisInBed];
//    
//    [self.healthStore aapl_mostRecentQuantitySampleOfType:sleepDurationType predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSError *error) {
//        if (!mostRecentQuantity) {
//            NSLog(@"Either an error occured fetching the user's sleep duration information or none has been stored yet. In your app, try to handle this gracefully.");
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                self.sleepDurationValueLabel.text = NSLocalizedString(@"Not available", nil);
//            });
//        }
//        else {
//            // Determine the weight in the required unit.
//            HKUnit *sleepDurationUnit = [HKUnit hourUnit];
//            double usersSleep = [mostRecentQuantity doubleValueForUnit:sleepDurationUnit];
//            
//            // Update the user interface.
//            dispatch_async(dispatch_get_main_queue(), ^{
//                self.sleepDurationValueLabel.text = [NSNumberFormatter localizedStringFromNumber:@(usersSleep) numberStyle:NSNumberFormatterNoStyle];
//            });
//        }
//    }];
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
    // Use an existing store
    CDTStore *store = _remotedatastore;
    
    Today *today = [[Today alloc] initWithId:1 steps:3412 caloriesBurned:3300 caloriesEaten:3450 sleepHours:8 ];
    
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

- (IBAction)sendData:(id)sender {
    [self saveDataToDb];
}
@end