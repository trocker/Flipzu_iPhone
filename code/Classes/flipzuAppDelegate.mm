//
//  flipzuAppDelegate.m
//  flipzu
//
//  Created by Lucas Lain on 5/18/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "flipzuAppDelegate.h"
#import "LoginController.h"
#import "EasyTracker.h"

@implementation flipzuAppDelegate

@synthesize window;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    

	// this increments the "flipzuUsage" counter. 
	// After several usages, it asks you to rate it.
	[Appirater appLaunched:YES];

    [EasyTracker launchWithOptions:launchOptions
                    withParameters:nil
                         withError:nil];

	return YES;
	
}

// Pre 4.2 support
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    NSLog(@"HandleOpenURL");
    
    UINavigationController *nc = (UINavigationController *)self.window.rootViewController;
    
    return [[nc.viewControllers lastObject] handleOpenURL:url];
}

// For 4.2+ support
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    NSLog(@"OpenURL");
        
    UINavigationController *nc = (UINavigationController *)self.window.rootViewController;
    
    return [[nc.viewControllers lastObject] handleOpenURL:url];
    
}

-(void)applicationDidEnterBackground:(UIApplication *)application {
	NSLog(@"App become active");
}

-(void)applicationDidBecomeActive:(UIApplication *)application {
	NSLog(@"App become active");	
}

- (void)dealloc {
    [window release];
    [super dealloc];
}


@end
