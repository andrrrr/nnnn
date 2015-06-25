//
//  LoginViewController.h
//  Fit
//
//  Created by andrew on 22-06-15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IMFGoogleAuthenticationHandler.h"
#import <GooglePlus/GooglePlus.h>
#import <GoogleOpenSource/GoogleOpenSource.h>


@interface LoginViewController : UIViewController <GPPSignInDelegate>

@end
