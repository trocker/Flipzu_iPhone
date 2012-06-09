//
//  LoginController.m
//  flipzu
//
//  Created by Lucas Lain on 2/13/12.
//  Copyright (c) 2012 Flipzu.com. All rights reserved.
//

#import "LoginController.h"


@implementation LoginController

@synthesize facebook;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    spinner.hidden = TRUE;
    
    // And then call switchToRec
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(doTimeout)
												 name:@"LOGINTIMEOUT"
                                               object:nil];
    
    // Wait for OK notification for login
	// And then call switchToTimeline
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loginOK)
                                                 name:@"LOGINOK"
                                               object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(enterBackground) 
												 name: UIApplicationDidEnterBackgroundNotification
											   object: nil];
    
    if([self already_validated] == TRUE) {
        [self performSegueWithIdentifier:@"goToTimeline" sender:self];
	}
    
    facebook = [[Facebook alloc] initWithAppId:@"130798790284829" andDelegate:self];

}

// This constructor checks if the user was already validated
- (bool) already_validated {
	FlipInterface *fi = [[FlipInterface alloc] init];
    
	bool validated = [fi already_validated];
    
	[fi release];
	
	return validated;		
}

- (void) enterBackground {
	NSLog(@"LoginView Enter Background");
}


- (void)loginOK {
    spinner.hidden = TRUE;
    [self performSegueWithIdentifier:@"goToTimeline" sender:self];
}

- (void) doTimeout {
    spinner.hidden = TRUE;
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection to Flipzu failed" 
													message:@"Maybe you are in a restricted LAN. Please check your internet connection." 
												   delegate:self 
										  cancelButtonTitle:@"OK" 
										  otherButtonTitles:nil];
	[alert show];
	[alert release];
	
}


- (IBAction) doFacebookLogin:(id)    sender {
    spinner.hidden = FALSE;
    NSArray *permissions = [[NSArray alloc] initWithObjects:
                            @"publish_stream",
                            @"offline_access",
                            @"email",
                            nil];
    
    
    [facebook authorize:permissions];
    
    [permissions release];
    permissions = nil;
    
}

#pragma FB Login methods
- (void) fbDidLogin {

    NSLog(@"FB did login");
    
    FlipInterface *fi = [[FlipInterface alloc] init];
	
	[fi do_fb_login:[facebook accessToken]];
    
	[fi release];
    
}

- (void)fbDidNotLogin:(BOOL)cancelled {
    NSLog(@"FB did not login - TODO: implement msg");
}

- (void) fbSessionInvalidated {
    NSLog(@"Session invalidated");
}

- (void) fbDidLogout {
    NSLog(@"FB logout");
}

- (void)fbDidExtendToken:(NSString*)accessToken
               expiresAt:(NSDate*)expiresAt {
    NSLog(@"FB did Extend token");
}

- (BOOL) handleOpenURL:(NSURL *)url
{
    return [facebook handleOpenURL:url];
}

- (void) viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [super viewWillAppear:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
