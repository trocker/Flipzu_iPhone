//
//  TimelineController.m
//  flipzu
//
//  Created by Lucas Lain on 6/6/11.
//  Copyright 2011 Flipzu.com. All rights reserved.
//

#import "TimelineViewController.h"


@implementation TimelineViewController

@synthesize recView;
@synthesize broadcasts;
@synthesize cell_for_height;
@synthesize fi;
@synthesize playerView;

- (void)viewDidLoad {
	
    [super viewDidLoad];
	NSLog(@"Load TimeControllerView");

	OSStatus error = AudioSessionInitialize(NULL, NULL, interruptionListener, self);
	
	if (error) 
		printf("ERROR INITIALIZING AUDIO SESSION! %d\n", (int)error);
	else 
	{
		[self startAudioSystem];
	}
		
	// Playback and Background notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(playbackQueueStopped)
												 name:@"playbackQueueStopped"
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(playbackQueueResumed)
												 name:@"playbackQueueResumed" 
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(enterBackground) 
												 name: UIApplicationDidEnterBackgroundNotification
											   object: nil];
	
    
    // Create the image obj manager
	objMan = [[HJObjManager alloc] initWithLoadingBufferSize:6 memCacheSize:20];
	
	// Create a file cache for the object manager to use
	// A real app might do this durring startup, allowing the object manager and cache to be shared by several screens
	NSString* cacheDirectory = [NSHomeDirectory() stringByAppendingString:@"/Library/Caches/imgcache/"] ;
	HJMOFileCache* fileCache = [[[HJMOFileCache alloc] initWithRootPath:cacheDirectory] autorelease];
	objMan.fileCache = fileCache;
	
	// Have the file cache trim itself down to a size & age limit, so it doesn't grow forever
	fileCache.fileCountLimit = 100;
	fileCache.fileAgeLimit   = 60*60*24*7; //1 week
	[fileCache trimCacheUsingBackgroundThread];
	
	fi = [[FlipInterface alloc] init];
    
	[self addCenterButtonWithImage:[UIImage imageNamed:@"golive.png"] highlightImage:nil];

	[tabBar setSelectedItem:all_list];

	NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TimelineCell" owner:self options:nil];
    self.cell_for_height = (TimelineCell *)[nib objectAtIndex:0];
	nib = nil;
    
    self.broadcasts = nil;
	
	[self setList:1];
    	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    if (_refreshHeaderView == nil) {
		
		EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 
                                                                                                      0.0f - tview.bounds.size.height, 
                                                                                                      self.view.frame.size.width,
                                                                                                      tview.bounds.size.height)];
		view.delegate = self;
		[tview addSubview:view];
		_refreshHeaderView = view;
		[view release];
		
	}
	
    [self reloadTableViewDataSource];
    
}


- (void) viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [super viewWillAppear:animated];
    
    NSIndexPath*	selection = [tview indexPathForSelectedRow];
	if (selection)
		[tview deselectRowAtIndexPath:selection animated:YES];
    
    // We delete the recorder pointer 
    // (needed for call interruption)
    self.recView = nil;

}

-(void) startAudioSystem {
	
	OSStatus error;
	
	// we do not want to allow recording if input is not available
	UInt32 inputAvailable = 0;
	UInt32 size = sizeof(inputAvailable);
	error = AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &inputAvailable);
	if (error) printf("ERROR GETTING INPUT AVAILABILITY! %d\n", (int)error);
	
	// We set the category according to the capabilities
	UInt32 category ;
	if (inputAvailable) {
		category = kAudioSessionCategory_PlayAndRecord;	
	} else {
		category = kAudioSessionCategory_MediaPlayback;	
		go_live.enabled = NO;
	}
	// ... and SET IT
	error = (int)AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
	if (error) printf("couldn't set audio category!");
	
	// Set the listener for audio route change 
	error = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, propListener, self);
	if (error) printf("ERROR ADDING AUDIO SESSION PROP LISTENER! %d\n", (int)error);
		
	// we also need to listen to see if input availability changes
	error = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioInputAvailable, propListener, self);
	if (error) printf("ERROR ADDING AUDIO SESSION PROP LISTENER! %d\n", (int)error);
	
	error = AudioSessionSetActive(true); 
	if (error) printf("AudioSessionSetActive (true) failed: %d\n",(int)error);
	
	// TODO Lucas: fix to increase volumen on playback
	UInt32 doChangeDefaultRoute = 1;        
    AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof (doChangeDefaultRoute), &doChangeDefaultRoute);

}

-(void) playbackQueueStopped {
	// "Now playing" Bar
	NSLog(@"StopNotification Called");
	if (! nowPlayingButton.hidden) {
		
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDuration:0.5];
		[UIView setAnimationBeginsFromCurrentState:YES];
		nowPlayingButton.hidden = TRUE;
		[tview setFrame:CGRectMake(0, tview.frame.origin.y - nowPlayingButton.frame.size.height, tview.frame.size.width, tview.frame.size.height + nowPlayingButton.frame.size.height)];
		[UIView commitAnimations];

	}
}

-(void) playbackQueueResumed {
	
	NSLog(@"ResumeNotification Called");
	if (nowPlayingButton.hidden) {
		nowPlayingButton.hidden = FALSE;
		[tview setFrame:CGRectMake(0, tview.frame.origin.y + nowPlayingButton.frame.size.height, tview.frame.size.width, tview.frame.size.height - nowPlayingButton.frame.size.height)];
	}
	
}

/*
 * Listeners 
 */
#pragma mark AudioSession listeners
void interruptionListener(	void *	inClientData,
						  UInt32	inInterruptionState) {
	
	TimelineViewController *THIS = (TimelineViewController *)inClientData;

	if( inInterruptionState == kAudioSessionEndInterruption ) {
		NSLog(@"Restarting audio interrupted");
		[THIS startAudioSystem];
	}
	
	
	NSLog(@"Interruption called");
    @try {
        if (inInterruptionState == kAudioSessionBeginInterruption)
		{
            if (THIS->recView &&
                THIS->recView.controller.recorder->IsRunning()) {
                
				[THIS->recView.controller start_stop_rec];
				[THIS->recView.controller enableDisableRec];
				NSLog(@"Recording interrupted");
                
			}
		} 
    }
    @catch (NSException *exception) {
        NSLog(@"Nothing to stop");
    }
	
}

void propListener(	void *                  inClientData,
				  AudioSessionPropertyID	inID,
				  UInt32					inDataSize,
				  const void *				inData) {
	
	
	//TimelineViewController *THIS = (TimelineViewController *)inClientData;
	if (inID == kAudioSessionProperty_AudioRouteChange)
	{
		NSLog(@"Changed audio route");
		
		CFDictionaryRef routeDictionary = (CFDictionaryRef)inData;			
		//CFShow(routeDictionary);
		CFNumberRef reason = (CFNumberRef)CFDictionaryGetValue(routeDictionary, CFSTR(kAudioSession_AudioRouteChangeKey_Reason));
		SInt32 reasonVal;
		CFNumberGetValue(reason, kCFNumberSInt32Type, &reasonVal);
		if (reasonVal != kAudioSessionRouteChangeReason_CategoryChange)
		{
			CFStringRef oldRoute = (CFStringRef)CFDictionaryGetValue(routeDictionary, CFSTR(kAudioSession_AudioRouteChangeKey_OldRoute));
			if (oldRoute)	
			{
				printf("old route: ");
				CFShow(oldRoute);
			}
			else 
				printf("ERROR GETTING OLD AUDIO ROUTE!\n");
			
			CFStringRef newRoute;
			UInt32 size; size = sizeof(CFStringRef);
			OSStatus error = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &newRoute);
			if (error) printf("ERROR GETTING NEW AUDIO ROUTE! %d\n", (int)error);
			else
			{
				printf("new route: ");
				CFShow(newRoute);
			}
			
			// NOTHING
			if (reasonVal == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {}
		}
	}
	
	

}

// Create a custom UIButton and add it to the center of our tab bar
-(void) addCenterButtonWithImage:(UIImage*)buttonImage highlightImage:(UIImage*)highlightImage
{
	UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
	button.frame = CGRectMake(0.0, 0.0, buttonImage.size.width, buttonImage.size.height);
	[button setBackgroundImage:buttonImage forState:UIControlStateNormal];
	[button setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
	
	CGFloat heightDifference = buttonImage.size.height - tabBar.frame.size.height;
	if (heightDifference < 0)
		button.center = tabBar.center;
	else
	{
		CGPoint center = tabBar.center;
		center.y = center.y - heightDifference/2.0;
		button.center = center;
	}
	
	[self.view addSubview:button];
	
	//listen for clicks
	[button  addTarget:self 
				action:@selector(BcastClicked:) // change this function
	  forControlEvents:UIControlEventTouchUpInside];
	
}

- (IBAction) NowPlayingClicked:(id)sender {
		
	[self.navigationController pushViewController:playerView animated:YES];
	
}

- (IBAction) LogoutClicked:(id)sender {
	
	// Remove the user data
	CoreDataInterface *ci = [[CoreDataInterface alloc] init];
	[ci delete_user];
	[ci release];
    
    [self.navigationController popViewControllerAnimated:YES];
		
}

-(void) enterBackground {
	NSLog(@"TimelineView Enter Background");
	// TODO (ver si está recorder y sino exit)
}

- (void)tabBar:(UITabBar *)theTabBar didSelectItem:(UITabBarItem *)item {
	NSLog(@"Clicked");

	
	if (item == friends_list) {
        [self setList:0];
		[self showLoading];
		[self reloadTableViewDataSource];
    } else if (item == all_list) {
        [self setList:1];
		[self showLoading];
		[self reloadTableViewDataSource];
    } else if (item == hot_list) {
        [self setList:2];
		[self showLoading];
		[self reloadTableViewDataSource];		
	} else if (item == mine_list) {
        [self setList:3];
		[self showLoading];
		[self reloadTableViewDataSource];	
	}
	
}
- (IBAction) BcastClicked:(id)sender {
    
	@try {
		if ([self.playerView.streamer isPlaying]) {
			[self.playerView.streamer stop];
		}
	} @catch (NSException * e) {
		NSLog(@"Nothing to stop");
	}
		
    [self performSegueWithIdentifier:@"goToRec" sender:self];

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    TimelineViewController *tc = sender;
    
    if ([[segue identifier] isEqualToString:@"goToRec"]) {
        
        // Get destination view
        tc.recView = [segue destinationViewController];
        
    }
    
    if ([[segue identifier] isEqualToString:@"goToPlayer"]) {
        
        NSIndexPath *indexPath = [tview indexPathForSelectedRow];
        
        // Get destination view
        playerView                    =  [[segue destinationViewController] retain];
        playerView.username           =  [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"username"];
        playerView.description        =  [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"text"];
        playerView.img_url            =  [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"img_url"];
        playerView.audio_url          =  [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"audio_url"];
        playerView.audio_url_fallback =  [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"audio_url_fallback"];
        playerView.liveaudio_url      =  [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"liveaudio_url"];
        playerView.is_live            =  [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"is_live"];
        playerView.time_str           =  [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"time_str"];
        playerView.listeners          =  [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"listens"];
        playerView.bcast_id           = [[[broadcasts objectAtIndex:indexPath.row] objectForKey:@"bid"] longLongValue];
		
        [now_playing setTitle: [NSString stringWithFormat:@"Now Playing: %@", playerView.username]  
                     forState: UIControlStateNormal];
        [playerView setObjMan:objMan];
        
    }
}

- (void)setList :(int)i {
	list = i;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [broadcasts count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	    
	// We rehuse the player and the object manager
	if (playerView == nil) {
        [self performSegueWithIdentifier:@"goToPlayer" sender:self];
	} else {
        
        // this reloads the previuos loaded player
        playerView.username           =  [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"username"];
        playerView.description        =  [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"text"];
        playerView.img_url            =  [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"img_url"];
        playerView.audio_url          =  [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"audio_url"];
        playerView.audio_url_fallback =  [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"audio_url_fallback"];
        playerView.liveaudio_url      =  [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"liveaudio_url"];
        playerView.is_live            =  [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"is_live"];
        playerView.time_str           =  [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"time_str"];
        playerView.listeners          =  [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"listens"];
        playerView.bcast_id           = [[[broadcasts objectAtIndex:indexPath.row] objectForKey:@"bid"] longLongValue];
		
        [now_playing setTitle: [NSString stringWithFormat:@"Now Playing: %@", playerView.username]  
                     forState: UIControlStateNormal];
        [playerView setObjMan:objMan];

        [self.navigationController pushViewController:playerView animated:YES];
        
	}
    
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"TimelineCellID";
	
	HJManagedImageV* mimg;
    
	cell = ((TimelineCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier]);
    if (cell == nil) {
		
		// We load the cell from the XIB file (TimelineCell.xib)
		[[NSBundle mainBundle] loadNibNamed:@"TimelineCell" owner:self options:nil];
		NSLog(@"Created Cell...cell");
		
		//Create a managed image view and add it to the cell (layout is very naieve)
		mimg = [[[HJManagedImageV alloc] initWithFrame:cell.avatar.bounds] autorelease];
		mimg.tag = 999;
		[mimg setMode:UIViewContentModeScaleToFill];
		[mimg setMask:(UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth)];
        
		[cell addSubview:mimg];
        
		
	} else {
		//Get a reference to the managed image view that was already in the recycled cell, and clear it
		mimg = (HJManagedImageV*)[cell viewWithTag:999];
		[mimg clear];
	}
    
	@try {
		
		NSString *te      = [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"text"];
		NSString *us      = [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"username"];
		NSString *img_url = [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"img_url"];
		NSString *listens = [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"listens"];
		NSString *live    = [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"is_live"];
		NSString *time_str= [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"time_str"];
        
		cell.desc.font         = [UIFont fontWithName:@"ArialMT" size:15];
		cell.username.font     = [UIFont fontWithName:@"Arial-BoldMT" size:14];
        
		if ([live isEqualToString:@"True"]) {
			cell.live.hidden = FALSE;
			cell.time_str.hidden = TRUE;
		} else {
			cell.time_str.hidden = FALSE;
			cell.live.hidden = TRUE;
		}
        
		
		if ([te isEqualToString:@""]) 
			te = @"New audio broadcast";
		
		
		cell.desc.numberOfLines = 2;
		cell.desc.text     = [NSString stringWithFormat:@"%@", te];
        
		// ... and the rest
		cell.username.text = [NSString stringWithFormat:@"%@", us];
		cell.details.text  = [NSString stringWithFormat:@"%@", listens] ;
		cell.time_str.text = [NSString stringWithFormat:@"%@", time_str] ;
        
		//set the URL that we want the managed image view to load
		mimg.url = [NSURL URLWithString:img_url];
		[objMan manage:mimg];
        
        
	} @catch (NSException *exception) {
		
		NSLog(@"TimelineController: Caught %@: %@", [exception name], [exception reason]);
		
	}
	
	cell.userInteractionEnabled = YES;
	cell.editing = NO;
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSString *te = [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"text"];
	NSString *us = [[broadcasts objectAtIndex:indexPath.row] objectForKey:@"username"];
	
	[cell_for_height desc].font     = [UIFont fontWithName:@"ArialMT" size:15];
	[cell_for_height username].font = [UIFont fontWithName:@"Arial-BoldMT" size:14];
	
	[[cell_for_height desc] setText:[NSString stringWithFormat:@"%@", te]];
	[[cell_for_height username] setText:[NSString stringWithFormat:@"%@", us]];
	
	CGSize constraint = CGSizeMake(270.0, 20000.0f);
	
	CGSize size = [[cell_for_height desc].text sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
	CGSize size2 = [[cell_for_height username].text sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
	
	// We return the content size (instead of the frame)
	float final_height =  size.height + size2.height + 7;
	
	if (final_height < 80.0) {
		return 80.0;
	} else {
		return final_height;
	}
	
}

// se corre en otro thread
- (void)doRefresh {
    
	NSAutoreleasePool *timerNSPool = [[NSAutoreleasePool alloc] init];
    NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
    
	@try {
		
		NSLog(@"Refresh List:%d",list);
		
		NSMutableArray * bcasts = [fi get_timeline:list];
		
		switch (list) {
			case 0:
				subTitle.text = @"Friends";
				break;
			case 1:
				subTitle.text = @"All";
				break;
			case 2:
				subTitle.text = @"Hot";
				break;
			default:
				break;
		}
		
		[self setBroadcasts:bcasts];
		[tview performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
        
	} @catch (NSException * e) {
		NSLog(@"Could not refresh timeline");
	}
	
	@finally {
		//[self performSelectorOnMainThread:@selector(stopLoading) withObject:nil waitUntilDone:YES];
		[self performSelectorOnMainThread:@selector(hideLoading) withObject:nil waitUntilDone:YES];
	}
	
	
	[runLoop run];
    [timerNSPool release];
	
}

- (void)hideLoading {
	
	[UIView beginAnimations:@"" context:nil];
    
	[activity stopAnimating];
	activity.hidden = TRUE;
	[activity_bg setAlpha:0.0];
	
	[UIView commitAnimations];
    
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];	
    
}


- (void)showLoading {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	activity.hidden = FALSE;
	[activity_bg setAlpha:0.5];
	[activity startAnimating];
}

#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource{
	
    //_reloading = YES;

    NSThread *refreshThread = [[NSThread alloc] initWithTarget:self selector:@selector(doRefresh) object:nil]; //Create a new thread
    [refreshThread start]; //start the thread
	[refreshThread release];
	
}

- (void)doneLoadingTableViewData{
	
	//  model should call this when its done loading
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:tview];
	
}


#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{	
	
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
	
}


#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	
    // NSLog(@"---------> REFRESH");

	[self reloadTableViewDataSource];
	[self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:3.0];
	
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	
	return _reloading; // should return if data source model is reloading
	
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	
	return [NSDate date]; // should return date data source was last changed
	
}

- (void) dealloc {
	NSLog(@"TimelineView dealloc");
    if (self.playerView) [playerView release];
    if (self.recView) [recView release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

@end
