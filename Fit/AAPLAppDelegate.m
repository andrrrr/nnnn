/*
    Copyright (C) 2015 IBM. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The main application delegate.
            
*/

#import "AAPLAppDelegate.h"
#import "AAPLProfileViewController.h"
#import <GooglePlus/GooglePlus.h>
#import "Today.h"
#import "healthKit.h"




@import HealthKit;

@interface AAPLAppDelegate()

@property (nonatomic) HKHealthStore *healthStore;


@end


@implementation AAPLAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.healthStore = [[HKHealthStore alloc] init];

    [self setUpHealthStoreForTabBarControllers];
    
    

    // Override point for customization after application launch.
    //Set Selected Tab Bar Item to Orange
    [[UITabBar appearance] setTintColor:[UIColor orangeColor]];
    [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];
    
    //Set Navigation BG to selected png pic
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"nav_bg.png"] forBarMetrics:UIBarMetricsDefault];
    
    //Remove grey shadow from BG pic on navigation bar
    [[UINavigationBar appearance]setShadowImage:[[UIImage alloc] init]];
    
    //Edit Navigation back item
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setBackIndicatorImage:[UIImage imageNamed:@"Back arrow.png"]];
    [[UINavigationBar appearance] setBackIndicatorTransitionMaskImage:[UIImage imageNamed:@"Back arrow.png"]];

    
    return YES;
}



//- (void)applicationDidBecomeActive:(UIApplication *)application {
//    [FBSDKAppEvents activateApp];
//}


- (BOOL)application: (UIApplication *)application
            openURL: (NSURL *)url
  sourceApplication: (NSString *)sourceApplication
         annotation: (id)annotation {
    return [GPPURLHandler handleURL:url
                  sourceApplication:sourceApplication
                         annotation:annotation];
}




#pragma mark - Convenience

- (void)setUpHealthStoreForTabBarControllers {
    
    
//    UITabBarController *tabBarController = (UITabBarController *)[self.window rootViewController];
//    
//    for (UINavigationController *navigationController in tabBarController.viewControllers) {
//        id viewController = navigationController.topViewController;
//        
//
//        if ([viewController respondsToSelector:@selector(setHealthStore:)]) {
//            [viewController setHealthStore:self.healthStore];
//        }
//    }

    
    
    UINavigationController *navigationController = (UINavigationController *)[self.window rootViewController];
    
    UITabBarController *tabBarController = navigationController.tabBarController;
    
    self.healthStore = [[HKHealthStore alloc] init];
    for (UINavigationController *navigationController in tabBarController.viewControllers) {
        
        id viewController = navigationController.topViewController;
        
        if ([viewController respondsToSelector:@selector(setHealthStore:)]) {
            [viewController setHealthStore:self.healthStore];
        }
    }
}





- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Notification Received" message:notification.alertBody delegate:nil 	cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    
    NSLog(@"NOTIFICATION RECEIVED");
//    AAPLProfileViewController *classs = [AAPLProfileViewController sharedInstanceOfMe];
//    [classs saveDataToDb];
//    [self saveDataToDb];
    [alertView show];
}

//- (void) saveDataToDb {
//    IMFDataManager *manager = [IMFDataManager sharedInstance];
//    [manager remoteStore:@"nndb" completionHandler:^(CDTStore *createdStore, NSError *error) {
//        if(error){
//            NSLog(@"Could not create remote store");
//        }else{
//            _remotedatastore = createdStore;
//            NSLog(@"Successfully created store: %@", _remotedatastore.name);
//            
//            [_remotedatastore.mapper setDataType:@"Today" forClassName:NSStringFromClass([Today class])];
//            
//        }
//    }];
//
//    
//    
//    [self getYesterday:^(Today *today) {
//        if(today){
//            [_remotedatastore save:today completionHandler:^(id savedObject, NSError *error) {
//                if (error) {
//                    NSLog(@"Error trying to save object to the cloud: %@", error);
//                } else {
//                    // use the result
//                    Today *savedToday = savedObject;
//                    NSLog(@"saved revision: %@", savedToday);
//                }
//            }];
//        }
//    }];
//}







- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"%s", __PRETTY_FUNCTION__);
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSLog(@"%s", __PRETTY_FUNCTION__);
    application.applicationIconBadgeNumber = 0;
}



//- (void)application:(UIApplication *)application didReceiveLocalNotification:    (UILocalNotification *)notification
//{
//    
//    NSLog(@"^^^^^^^######## NOTIFICATION");
//    application.applicationIconBadgeNumber = 0;
//    [[[AAPLProfileViewController alloc] init] saveDataToDb];
//
//}




- (void)applicationDidEnterBackground:(UIApplication *)application
{
    _bgTask = [application beginBackgroundTaskWithName:@"MyTask" expirationHandler:^{
        // Clean up any unfinished task business by marking where you
        // stopped or ending the task outright.
        [application endBackgroundTask:_bgTask];
        _bgTask = UIBackgroundTaskInvalid;
    }];
    
    // Start the long-running task and return immediately.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Do the work associated with the task, preferably in chunks.
        
        [application endBackgroundTask:_bgTask];
        _bgTask = UIBackgroundTaskInvalid;
    });
}

@end
