//
//  ContainerViewController.h
//  Fit
//
//  Created by andrew on 25-06-15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContainerViewController : UIViewController

@property (nonatomic, weak) ContainerViewController *containerViewController;

- (void)swapViewControllers;

@end

