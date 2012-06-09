//
//  LoginController.m
//  flipzu
//
//  Created by Lucas Lain on 5/18/10.
//  Copyright 2010 Flipzu. All rights reserved.
//

#import "TWLoginController.h"


@implementation TWLoginController

- (void)viewDidLoad {
    
	NSLog(@"Login LOAD");
        
    loginTwitter.hidden = FALSE;
	spinner.hidden = TRUE;
	err_msg.hidden = TRUE;
    		
	//*** TWITTER STUFF
	twitter = [[MGTwitterEngine alloc] initWithDelegate:self] ;
	[twitter setConsumerKey:@"AwuBZXmskKcD5xPs8zNA" secret:@"Uu1vgcneoCido3YU4HjlR9GBUFtWHWLTpYL1tfPt8"];
    
}

- (void) viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [super viewWillAppear:animated];
    spinner.hidden = TRUE;
    [passField setText:nil];

}

/**********************/
/** Twitter  methods **/
/**********************/
-(IBAction) doTwitterLogin: (id) sender {
	
	spinner.hidden = FALSE;
	err_msg.hidden = TRUE;
	[spinner startAnimating];

	// send the request and the callback will take care
	[twitter getXAuthAccessTokenForUsername:userField.text 
                                   password:passField.text];
	
}

- (void)accessTokenReceived:(OAToken *)token forRequest:(NSString *)connectionIdentifier {
 
	// We must put the delegate with null for future callbacks prevention
	//  ...if not, dealloc will be called, and we will have a null pointer exception 
	//  in the "connectionFinished" callback on MGTwitterEngine	
	
	// TODO LUCAS :: If we logout, we can't reconnect
	// [twitter setDelegate:nil];

	FlipInterface *fi = [[FlipInterface alloc] init];
	
	[fi do_tw_login:[NSString stringWithFormat:@"1&oauth_token_secret=%@&oauth_token=%@",[token secret], [token key]]];
			
	[fi release];
    
    loginTwitter.hidden = FALSE;
	err_msg.hidden = TRUE;
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
	
	[theTextField resignFirstResponder];
	return YES;

}

- (void)requestFailed:(NSString *)requestIdentifier withError:(NSError *)error {
	
	loginTwitter.hidden = FALSE;
	spinner.hidden = TRUE;
	err_msg.hidden = FALSE;
	err_msg.text = @"Invalid user/pass";
	passField.text = nil;

	
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc {
	NSLog(@"Login Controller dealloc");
	[userField release];
	[passField release];
	[twitter release];
	[super dealloc];
}

@end
