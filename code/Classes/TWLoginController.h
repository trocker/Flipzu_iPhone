//
//  LoginController.h
//  flipzu
//
//  Created by Lucas Lain on 5/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
// #import "RecViewController.h"
#import "FlipInterface.h"
#import "MGTwitterEngine.h"

@class RecViewController;

@interface TWLoginController : UIViewController {
	
	IBOutlet UITextField *userField;
	IBOutlet UITextField *passField;
	IBOutlet UIImageView *mediumLogo;
	IBOutlet UIButton *loginTwitter;
	IBOutlet UILabel *err_msg;
	IBOutlet UIActivityIndicatorView *spinner;
	
	MGTwitterEngine *twitter;
	
}

- (IBAction) doTwitterLogin: (id) sender;


@end