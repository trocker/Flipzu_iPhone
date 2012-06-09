//
//  LoginController.h
//  flipzu
//
//  Created by Lucas Lain on 2/13/12.
//  Copyright (c) 2012 Flipzu.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Facebook.h"
#import "FlipInterface.h"

@interface LoginController : UIViewController <FBSessionDelegate> {
    Facebook *facebook;
    IBOutlet UIActivityIndicatorView *spinner;

}

@property (nonatomic, retain) Facebook *facebook;


- (BOOL) handleOpenURL:(NSURL *)    url;
- (IBAction) doFacebookLogin:(id)   sender;
- (void) fbDidLogin;
- (bool) already_validated;

@end
