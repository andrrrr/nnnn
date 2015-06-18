/*
    Copyright (C) 2015 IBM. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The main application delegate.
            
*/

#import "AAPLAppDelegate.h"
#import "AAPLProfileViewController.h"
#import "AAPLJournalViewController.h"
#import "AAPLEnergyViewController.h"
#import "IMFFacebookAuthenticationHandler.h"
//#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <GooglePlus/GooglePlus.h>



@import HealthKit;


@interface AAPLAppDelegate()

@property (nonatomic) HKHealthStore *healthStore;


@end


@implementation AAPLAppDelegate



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.healthStore = [[HKHealthStore alloc] init];

    [self setUpHealthStoreForTabBarControllers];
    
//    return [[FBSDKApplicationDelegate sharedInstance] application:application
//                                    didFinishLaunchingWithOptions:launchOptions];
    
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


//FACEBOOK
//- (BOOL)application:(UIApplication *)application
//            openURL:(NSURL *)url
//  sourceApplication:(NSString *)sourceApplication
//         annotation:(id)annotation {
//    return [[FBSDKApplicationDelegate sharedInstance] application:application
//                                                          openURL:url
//                                                sourceApplication:sourceApplication
//                                                       annotation:annotation];
//}

#pragma mark - Convenience

// Set the healthStore property on each view controller that will be presented to the user. The root view controller is a tab
// bar controller. Each tab of the root view controller is a navigation controller which contains its root view controller—
// these are the subclasses of the view controller that present HealthKit information to the user.
- (void)setUpHealthStoreForTabBarControllers {
    UITabBarController *tabBarController = (UITabBarController *)[self.window rootViewController];

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
    [alertView show];
    
    AAPLProfileViewController *classs = [AAPLProfileViewController sharedInstanceOfMe];
    [classs saveDataToDb];
}


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
