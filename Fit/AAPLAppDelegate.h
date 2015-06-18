/*
    Copyright (C) 2015 IBM. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The main application delegate.
            
*/

#import <IMFPush/IMFPush.h>
#import "IMFURLProtocol.h"

@import UIKit;

@interface AAPLAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property UIBackgroundTaskIdentifier bgTask;

@end

