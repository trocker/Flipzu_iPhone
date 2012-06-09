//
//  flipzuAppDelegate.h
//  flipzu
//
//  Created by Lucas Lain on 5/18/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Appirater.h"
#import "TimelineViewController.h"


@interface flipzuAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow                            * window;
}

@property (nonatomic, retain) IBOutlet UIWindow                 * window;

@end

