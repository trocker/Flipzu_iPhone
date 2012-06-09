//
//  RecController.mm
//  flipzu
//
//  Created by Lucas Lain on 5/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RecController.h"


@implementation RecController

@synthesize recorder;
@synthesize ci;
@synthesize fi;
@synthesize mi;
@synthesize user;
@synthesize seconds_label;
@synthesize recButton;
@synthesize timer;
@synthesize backButton;
@synthesize responseKey;

@synthesize lvlMeter_in;
@synthesize cc;

- (void)stopRecord
{

	// To save the last words =)
	NSLog(@"Actually stopping...");
	
	// Disconnect our level meter from the audio queue
	[lvlMeter_in setAq: nil];
	
	recorder->StopRecord();
    
}

- (void) enableDisableRec {
	
	if (recButton.enabled == YES) {
		recButton.enabled = NO;
	} else {
		recButton.enabled = YES;
	}
}


- (IBAction) btnRec_Clicked:(id)sender {
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(start_stop_rec) object:nil];
	
	recButton.enabled = NO;

	if (!recorder->IsRunning()) {
				
		NSString *conn_status = [NSString stringWithFormat:@"Connecting ... ( to http://flipzu.com/%@ )", user.username];
	
		NSDictionary *status = [NSDictionary dictionaryWithObjectsAndKeys:
							@"Flipzu Status", @"username", 
							conn_status, @"text",
							nil];
	
		NSArray  *status_array = [NSArray arrayWithObject:status];
	
		[cc setComments:status_array];
		
		[cc.tableView reloadData];
	
	}
	
	[self performSelector:@selector(start_stop_rec) withObject:nil afterDelay:.5];
	
}

- (BOOL) isRunning {
	return recorder->IsRunning();
}

- (void) start_stop_rec {
	
	if (recorder->IsRunning()) // If we are currently recording, stop and save the file.
	{
		// We reset all the buttons
		recButton.selected = NO;
		bcast_title.enabled = YES;
        
		bcast_title.placeholder = @"Enter broadcast title...";
			
		[self stopRecord];
		
		// We record the significant event
		[Appirater userDidSignificantEvent:YES];
		
		// We stop the sending of media. 
		mi.mustStop = TRUE;
		[mi release];
        mi = nil;
				
		NSString *finished_bcast = [NSString stringWithFormat:@"Go back to the Main Screen to listen"];
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Broadcast Finished OK"
														message:finished_bcast 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		
		[alert show];
		[alert release];
		
		[timer invalidate];
		timer = nil;
		
		backButton.enabled = YES;
        
        [self->responseKey release];
        self->responseKey = nil;

		
	}
	else // If we're not recording, start.
	{
		
		// Relese focus on the bcast title
		[bcast_title resignFirstResponder];
		
		// Request a new bcast key to flipzu
		self->responseKey = [fi new_key:bcast_title.text :twButton.selected :fbButton.selected ];
		
		// We got the key from the server
		if (self->responseKey.status == @"OK") {
            
			// Connect to the network
			mi = [[MediaInterface alloc] init] ;
            
            //NSLog(@"Retain count 1: %d", [mi retainCount]);

			AudioSessionSetActive(true); 

			if (recorder->StartRecord((CFStringRef)self->responseKey.key, mi)) {
								
				NSLog(@"Server says: %@, %@",self->responseKey.key,self->responseKey.mediahost);
				
                networkThread = [[NSThread alloc] initWithTarget:self selector:@selector(doStartNetworkThread) object:nil]; //Create a new thread
                [networkThread start]; //start the thread
                
                // We change the buttons 
                recButton.selected = YES;
                bcast_title.enabled = NO;
                bcast_title.placeholder = @"(No title)";
                backButton.enabled = NO;
                
                // We remove the "connecting" status
                [cc setComments:nil];
                [cc.tableView reloadData];
                
                [lvlMeter_in setAq: recorder->Queue()];
                
				
			} else {
				
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error starting Audio System"
																message:@"You need an IPhone 3Gs or Better..." 
															   delegate:self 
													  cancelButtonTitle:@"OK" 
													  otherButtonTitles:nil];
				[alert show];
				[alert release];
				
				
                // Release the Media interface
                mi.mustStop = TRUE;
                [mi release];
                mi = nil;

				
			} // EndOf StartRecord //
						
		} else {
			
			// Error on request Key
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot connect" 
															message:self->responseKey.message 
														   delegate:self 
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];
			[alert show];
			[alert release];
						
		}
		
	}
	
	// [Message release];
	
	// this is to "clean" all the clicks while disabled
	[self performSelector:@selector(enableDisableRec) withObject:nil afterDelay:.1];

	
}


- (void) doStartNetworkThread {
    
    // TO extend the background time in case of close and background inmediately
	UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication]
										 beginBackgroundTaskWithExpirationHandler:^{}];
	
	
	NSAutoreleasePool *timerNSPool = [[NSAutoreleasePool alloc] init];
    NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
	    
    // ... get the new ID
    int bcast_id = [mi doConnect:(NSString *)self->responseKey.key 
                                :(NSString *)self->responseKey.mediahost 
                                :(NSString *)self->responseKey.mediaport];
    
    if(bcast_id == -1) {
        
        // to separate a little bit the error
        usleep(100000);
        
        [self stopRecord];
        
        // if the timer is not invalidated, the retain is incremented
        [mi.timer invalidate];
        
        // Release the Media interface
        recorder->mi = nil;
        [self->mi release];
        self->mi = nil;
        
        // Everything went fucking wrong (shit!)
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed to Authenticate with Media Server"
                                                        message:@"Please try again..." 
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles:nil];
        
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
        [alert release];
        
        // We reset all the buttons
		recButton.selected = NO;
		bcast_title.enabled = YES;
        
        
        perror("MediaInterface");
        
        
    } else {
        
        
        /**********************************
         HERE WE KNOW THAT IT IS RECORDING 
         **********************************/
 
        // We remove the "connecting" status
        [cc setComments:nil];
        [cc.tableView reloadData];
        
        // set the bcast ID for comments 
        // ...& assign the queue for Audio
        [cc setBcast_id:bcast_id];
        
        // (WARN:::: Does not leave "startNetworkThread" until it finishes)
        // Start network thread and go recording
        [mi startNetworkThread];
        
    }
    
    [runLoop run];
    [timerNSPool release];
    
	[[UIApplication sharedApplication] endBackgroundTask:bgTask];

	
}

- (void) disableMeter {
	[lvlMeter_in setInBackground:TRUE];
}

- (void) enableMeter {
	[lvlMeter_in setInBackground:FALSE];
}

- (void) countUp {
	
	seconds_running++;
	
	int minutes = int(seconds_running / 60);
	int seconds = seconds_running % 60;
	
	NSString *s_minutes;
	NSString *s_seconds;
	
	if (minutes < 10) {
		s_minutes = [NSString stringWithFormat:@"0%i", minutes];
	} else {
		s_minutes = [NSString stringWithFormat:@"%i", minutes];
	}
	
	if (seconds < 10) {
		s_seconds = [NSString stringWithFormat:@"0%i", seconds];
	} else {
		s_seconds = [NSString stringWithFormat:@"%i", seconds];
	}

	seconds_label.text = [NSString stringWithFormat:@"%@:%@", s_minutes, s_seconds];
	
}

- (IBAction) fbButtonClicked:(id)sender {
	if ([user.has_facebook intValue] != 1) {
		// Facebook share notification
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook Share" 
														message:@"Please visit http://flipzu.com ('Settings' section) to bind your Facebook Account. Then Re-Login on this app." 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
	} else {
		fbButton.selected = fbButton.selected == YES ? NO : YES; 
	}

}

- (IBAction) twButtonClicked:(id)sender {
	if ([user.has_twitter intValue] != 1) {
		// Facebook share notification
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Twitter Share" 
														message:@"Please visit http://flipzu.com ('Settings' section) to bind your Twitter Account. Then Re-Login on this app." 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
	} else {
		twButton.selected = twButton.selected == YES ? NO : YES; 
	}
    
}

#pragma mark Initialization routines
- (void) awakeFromNib {
    
    NSLog(@"RecController: Awake from nib");
    
    [super awakeFromNib];
        
	// Allocate our singleton instance for the recorder & player object
	recorder = new AQRecorder();
	
	ci = [[CoreDataInterface alloc] init];
	user = [ci new_current_user];
	
	fi = [[FlipInterface alloc] init];
	
	UIColor *bgColor = [[UIColor alloc] initWithRed:244/255.0 green:204/255.0 blue:6/255.0 alpha:0.0];
	[lvlMeter_in setBackgroundColor:bgColor];
	[lvlMeter_in setBorderColor:bgColor];
	[bgColor release];
	    	
	NSLog(@"RecController: Awake from nib ended");
        
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
	
	[theTextField resignFirstResponder];
	return YES;
	
}

- (void)dealloc {
	NSLog(@"Rec Controller dealloc");
	if (recorder->IsRunning()) // If we are currently recording, stop and save the file.
	{
		recButton.selected = NO;
		[self stopRecord];
	}
		
	// This will call the destructor
	delete recorder;
	
	[fi release];
	[ci release];
	[cc release];
	[user release];
	[seconds_label release];
	[recButton release];
    [super dealloc];
}


@end
