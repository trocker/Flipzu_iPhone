    //
//  RecController.m
//  flipzu
//
//  Created by Lucas Lain on 5/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RecViewController.h"


@implementation RecViewController

@synthesize controller,comment_controller;


- (void)didReceiveMemoryWarning {
	
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
	
}

- (void) viewDidLoad {
	
	NSLog(@"Load RecView ");
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(enterBackground) 
												 name: UIApplicationDidEnterBackgroundNotification
											   object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(resumeBackground) 
												 name: UIApplicationDidBecomeActiveNotification
											   object: nil];
    
    CoreDataInterface * ci = [[CoreDataInterface alloc] init];
	ValueUser * user = [ci new_current_user];
    
    // Default STATE for social buttons
	if ([user.has_twitter integerValue] == 1) {
        [twButton setSelected:YES];
	}
	if ([user.has_facebook integerValue] == 1) {
		[fbButton setSelected:YES];
        
	}
    
    [user release];
    [ci release];
    			
}

- (IBAction) BackButtonClicked:(id)sender {
	    
    [self.navigationController popViewControllerAnimated:YES];
	
}

- (void) enterBackground {
	NSLog(@"RecView Enter Background");
	[comment_controller doPause];
	[controller disableMeter];

}

- (void) resumeBackground {
	NSLog(@"RecView Resume Background");
	[comment_controller doResume];
	[controller enableMeter];
}

- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	// This method invalidates the timer
	//  ... and decrements the comments_controller retain count
    // (IMPORTANT: The timer must be cancelled from the same thread it was activated)
    comment_controller.mustStop = TRUE;

	// this must be "Count:1:6"
	NSLog(@"RecView Dealloc. Controller/CommController retains: %d/%d",[controller retainCount], [comment_controller retainCount]);

    // RecView should dealloc on his own
	[self.controller release];
    [self.comment_controller release];
    
    [super dealloc];
}


@end
