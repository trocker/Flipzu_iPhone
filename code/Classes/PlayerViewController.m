//
//  PlayerViewController.m
//  flipzu
//
//  Created by Lucas Lain on 6/10/11.
//  Copyright 2011 Flipzu.com. All rights reserved.
//

#import "PlayerViewController.h"
#import "AudioStreamer.h"
#import <MediaPlayer/MediaPlayer.h>
#import <CFNetwork/CFNetwork.h>
#import <QuartzCore/CoreAnimation.h>

@implementation PlayerViewController

@synthesize objMan;
@synthesize mimg;
@synthesize img_url;
@synthesize username;
@synthesize description;
@synthesize time_str;
@synthesize to_play_url;
@synthesize audio_url;
@synthesize audio_url_fallback;
@synthesize liveaudio_url;
@synthesize previous_audio_url;
@synthesize is_live;
@synthesize streamer;
@synthesize listeners;
@synthesize bcast_id;
@synthesize fi;

- (void) viewDidLoad {
	
	NSLog(@"Player: viewDidLoad");
	
	// we initialize the manager
	if( mimg == nil ) {
		mimg = [[[HJManagedImageV alloc] initWithFrame:pimage.bounds] autorelease];
		[pimage addSubview:mimg];
		[mimg setMode:UIViewContentModeScaleAspectFit];
		[mimg setMask:UIViewAutoresizingFlexibleWidth];
		[self.view bringSubviewToFront:playButton];
	}
	
	descriptionView.text = self.description;
	usernameView.text = self.username;
	listenersView.text = self.listeners;
	time_strView.text = self.time_str;
		
	// this starts the comments
	[comment_controller setBcast_id:self.bcast_id];

	fi = [[FlipInterface alloc] init];
	
	// clear the view and go get it
	[mimg clear];
	mimg.url = [NSURL URLWithString:img_url];
	[objMan manage:mimg];
	
	// Try reconnection
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(retryCallback)
												 name:@"STREAM_NOT_FOUND"
											   object:nil];
	
	
	// Keyboard show and keyboard hide
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (keyboardWillShow:)name: UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (keyboardWillHide:)name: UIKeyboardWillHideNotification object:nil];
	
	
	// bouncing arrow
	[self showCommentsHelper];
	
	NSLog(@"Loading");
	
}

- (void) viewDidAppear:(BOOL)animated {
	
	NSLog(@"Player: viewDidAppear");
		
	// if not equal, we stop the previous bcast
	if(! ([previous_audio_url  isEqualToString:audio_url]
	   || [previous_audio_url  isEqualToString:audio_url_fallback]
	   || [previous_audio_url  isEqualToString:liveaudio_url]) ) {
		
		if (streamer) {
			[streamer stop];
			[self destroyStreamer];
		}
		
		// Clear the previous comments and start over
		[comment_controller doPause];
		[comment_controller setBcast_id:self.bcast_id];
		[comment_controller clearAll];
		[comment_controller doResume];
		[self showCommentsHelper];

	}
	
	// Title and stuff
	usernameView.text = self.username;
	descriptionView.text = self.description;
	listenersView.text = self.listeners;
	time_strView.text = self.time_str;
    
    [self setTitle:self.username];
	
	// Set the default title
	if ([self.description isEqualToString:@""]) 
		descriptionView.text = @"New audio broadcast";
	
	// Show or hide "live" sign
	if ([is_live isEqualToString:@"True"]) {
		live.hidden = FALSE;
		time_strView.hidden = TRUE;
		to_play_url = liveaudio_url;
		
	} else {
		live.hidden = TRUE;
		time_strView.hidden = FALSE;
		to_play_url = audio_url;
	}

	
	// Cached profile image 
	[mimg clear];
	mimg.url = [NSURL URLWithString:img_url];
	[objMan manage:mimg];
	
	NSLog(@"Appear");
	
	if (!streamer || ![streamer isPlaying]) {
		NSLog(@"Playing Now");
		
		// INSIDE createStreamer we select the broadcast
		[self createStreamer];
		[self setButtonImage:[UIImage imageNamed:@"loadingbutton.png"]];
		[streamer start];
		
		// for "playing now" button
		[[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueResumed" object:nil];

	}
	
	[super viewDidAppear:animated];

}

- (void) retryCallback {
	[self performSelectorOnMainThread:@selector(tryRecordedBroadcast) withObject:nil waitUntilDone:YES];
}

- (void) tryRecordedBroadcast {
		
	if([previous_audio_url isEqualToString:liveaudio_url]) {
		
		NSLog(@"Trying to reconnect to the offline broadcast");
		
		// We destroy the "live" status
		live.hidden = TRUE;
		time_strView.hidden = FALSE;

		to_play_url = audio_url;
		
		[[NSNotificationCenter defaultCenter]
		 removeObserver:self
		 name:ASStatusChangedNotification
		 object:streamer];
		[streamer release];
		streamer = nil;

		// INSIDE createStreamer we select the broadcast
		[self createStreamer];
		[self setButtonImage:[UIImage imageNamed:@"loadingbutton.png"]];
		[streamer start];
		
	} else if ([previous_audio_url isEqualToString:audio_url]) {
		
		NSLog(@"Trying to reconnect to the fallback broadcast");
		
		// We destroy the "live" status
		live.hidden = TRUE;
		time_strView.hidden = FALSE;
		
		to_play_url = audio_url_fallback;
		
		// NSLog(@"audio_url, fallback: %@,%@",audio_url, audio_url_fallback);
		
		[[NSNotificationCenter defaultCenter]
		 removeObserver:self
		 name:ASStatusChangedNotification
		 object:streamer];
		[streamer release];
		streamer = nil;
		
		// INSIDE createStreamer we select the broadcast
		[self createStreamer];
		[self setButtonImage:[UIImage imageNamed:@"loadingbutton.png"]];
		[streamer start];
		
	} else {
	
		NSLog(@"Broadcast not available");

		// Everything went fucking wrong (shit!)
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Broadcast not available"
														message:@"Broadcast is processing or might be deleted by the user." 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		
		[self setButtonImage:[UIImage imageNamed:@"playButton.png"]];

		
		[alert show];
		[alert release];
		
	}
	

}

//
// setButtonImage:
//
// Used to change the image on the playbutton. This method exists for
// the purpose of inter-thread invocation because
// the observeValueForKeyPath:ofObject:change:context: method is invoked
// from secondary threads and UI updates are only permitted on the main thread.
//
// Parameters:
//    image - the image to set on the play button.
//
- (void)setButtonImage:(UIImage *)image
{
	[playButton.layer removeAllAnimations];
	if (!image)
	{
		[playButton setImage:[UIImage imageNamed:@"playButton.png"] forState:0];
	}
	else
	{
		[playButton setImage:image forState:0];
		
		if ([playButton.currentImage isEqual:[UIImage imageNamed:@"loadingbutton.png"]])
		{
			[self spinButton];
		}	
	}
}

- (void)spinButton
{
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	CGRect frame = [playButton frame];
	playButton.layer.anchorPoint = CGPointMake(0.5, 0.5);
	playButton.layer.position = CGPointMake(frame.origin.x + 0.5 * frame.size.width, frame.origin.y + 0.5 * frame.size.height);
	[CATransaction commit];
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanFalse forKey:kCATransactionDisableActions];
	[CATransaction setValue:[NSNumber numberWithFloat:2.0] forKey:kCATransactionAnimationDuration];
	
	CABasicAnimation *animation;
	animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
	animation.fromValue = [NSNumber numberWithFloat:0.0];
	animation.toValue = [NSNumber numberWithFloat:2 * M_PI];
	animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionLinear];
	animation.delegate = self;
	[playButton.layer addAnimation:animation forKey:@"rotationAnimation"];
	
	
	[CATransaction commit];
}

- (void)showCommentsHelper
{
	label_comments.hidden = FALSE;
	arrow_comments.hidden = FALSE;
    
    int moving_point = arrow_comments.frame.origin.y + (arrow_comments.frame.size.height / 2);
    
    [CATransaction begin];
	CABasicAnimation *bounceAnimation = [CABasicAnimation animationWithKeyPath:@"position.y"];
	bounceAnimation.duration = 1;
	bounceAnimation.fromValue = [NSNumber numberWithInt:moving_point];
	bounceAnimation.toValue = [NSNumber numberWithInt:moving_point - 10];
	bounceAnimation.repeatCount = 10;
	bounceAnimation.autoreverses = YES;
	bounceAnimation.fillMode = kCAFillModeForwards;
	bounceAnimation.removedOnCompletion = NO;
	[arrow_comments.layer addAnimation:bounceAnimation forKey:@"bounceAnimation"];
	[CATransaction commit];
}

//
// destroyStreamer
//
// Removes the streamer, the UI update timer and the change notification
//
- (void)destroyStreamer
{
	if (streamer)
	{
		[[NSNotificationCenter defaultCenter]
		 removeObserver:self
		 name:ASStatusChangedNotification
		 object:streamer];
		//[progressUpdateTimer invalidate];
		// progressUpdateTimer = nil;
		[streamer stop];
		[streamer release];
		streamer = nil;

	}
}

//
// createStreamer
//
// Creates or recreates the AudioStreamer object.
//
- (void)createStreamer
{
	if (streamer)
	{
		return;
	}
	
	[self destroyStreamer];
		
	NSString *escapedValue =
	[(NSString *)CFURLCreateStringByAddingPercentEscapes(
														 nil,
														 (CFStringRef)to_play_url,
														 NULL,
														 NULL,
														 kCFStringEncodingUTF8)
	 autorelease];
	
		
	// the user is not live
	NSURL *url = [NSURL URLWithString:escapedValue];
		
	streamer = [[AudioStreamer alloc] initWithURL:url];
		
	self.previous_audio_url = escapedValue;
	

	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(playbackStateChanged:)
	 name:ASStatusChangedNotification
	 object:streamer];
}


- (IBAction) PlayPauseButtonClicked:(id)sender {
	if ([playButton.currentImage isEqual:[UIImage imageNamed:@"playButton.png"]])
	{	
		NSLog(@"Playing");
		[self createStreamer];
		[self setButtonImage:[UIImage imageNamed:@"loadingbutton.png"]];
		[streamer start];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueResumed" object:nil];

	}
	else
	{
		NSLog(@"Stoping");
		[streamer stop];

	}
}

- (BOOL)textFielsShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

//
// playbackStateChanged:
//
// Invoked when the AudioStreamer
// reports that its playback status has changed.
//
- (void)playbackStateChanged:(NSNotification *)aNotification
{
	if ([streamer isWaiting])
	{
		[self setButtonImage:[UIImage imageNamed:@"loadingbutton.png"]];
	}
	else if ([streamer isPlaying])
	{
		[self setButtonImage:[UIImage imageNamed:@"pauseButton.png"]];
	}
	else if ([streamer isIdle])
	{
		[self destroyStreamer];
		[self setButtonImage:[UIImage imageNamed:@"playButton.png"]];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueStopped" object:nil];
	}

}

-(void) keyboardWillShow: (NSNotification *)notif {
    NSLog(@"---------->Keyboard show");
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationBeginsFromCurrentState:YES];
	
	comment_txt.frame = CGRectMake(comment_txt.frame.origin.x, (comment_txt.frame.origin.y - 65), comment_txt.frame.size.width, comment_txt.frame.size.height);
	bg_post_comment.frame = CGRectMake(bg_post_comment.frame.origin.x, (bg_post_comment.frame.origin.y - 65), bg_post_comment.frame.size.width, bg_post_comment.frame.size.height);
	[UIView commitAnimations];
	
}
-(void) keyboardWillHide: (NSNotification *)notif {

	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDuration:0.1];
	[UIView setAnimationBeginsFromCurrentState:YES];
	
	comment_txt.frame = CGRectMake(comment_txt.frame.origin.x, (comment_txt.frame.origin.y + 65), comment_txt.frame.size.width, comment_txt.frame.size.height);
	bg_post_comment.frame = CGRectMake(bg_post_comment.frame.origin.x, (bg_post_comment.frame.origin.y + 65), bg_post_comment.frame.size.width, bg_post_comment.frame.size.height);
	[UIView commitAnimations];
	[self.view bringSubviewToFront:spinner];
	
}

- (IBAction) PostComment:(id)sender {
	
	//[comment_txt resignFirstResponder];
	spinner.hidden = FALSE;
	[spinner startAnimating];
		
	[self performSelector:@selector(doPost) withObject:nil afterDelay:1];

}

- (void) doPost {
	if (comment_txt.text) {
		[fi post_comment:comment_txt.text :self.bcast_id];
	}
	
	spinner.hidden = TRUE;
	[spinner stopAnimating];
	comment_txt.text = nil;
}

- (IBAction) BackButtonClicked:(id)sender {
	
	[comment_txt resignFirstResponder];
	
	[self.navigationController popViewControllerAnimated:YES];
	
}

- (void)dealloc {
	NSLog(@"player dealloc");
	mimg = nil;
	[fi release];
	[self destroyStreamer];
    [super dealloc];
}


@end
