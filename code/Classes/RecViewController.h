//
//  RecViewController.h
//  flipzu
//
//  Created by Lucas Lain on 5/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommentsController.h"
#import "CoreDataInterface.h"
#import "RecController.h"

//@class RecController;
@class CommentsController;
@class flipzuAppDelegate;

@interface RecViewController : UIViewController {
	IBOutlet RecController			*controller;
	IBOutlet CommentsController		*comment_controller;
    IBOutlet UIButton*				twButton;
	IBOutlet UIButton*				fbButton;
}

@property (nonatomic, retain) CommentsController	*comment_controller;
@property (nonatomic, retain) RecController			*controller;

- (IBAction) BackButtonClicked:(id)sender;
- (void)     enterBackground;
- (void)     resumeBackground;

@end
