//
//  WDCAppDelegate.h
//  WWDC
//
//  Created by Genady Okrain on 5/17/14.
//  Copyright (c) 2014 Sugar So Studio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FBTweakInline.h>

@interface WDCAppDelegate : UIResponder <UIApplicationDelegate, FBTweakObserver>

@property (strong, nonatomic) UIWindow *window;

@end