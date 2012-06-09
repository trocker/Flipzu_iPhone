//
//  CommentsController.m
//  flipzu
//
//  Created by Lucas Lain on 5/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CommentsController.h"


@implementation CommentsController

@synthesize comments;
@synthesize fi;
@synthesize listeners;
@synthesize timer_REQ;
@synthesize mustStop;
@synthesize server_listeners;
@synthesize bcast_id;
@synthesize cell_for_height;
@synthesize is_for_broadcast;


- (CommentsController *)init {
    
    NSLog(@"Init Comments controller");
    
    self = [super init];
		
	fi = [FlipInterface new];

	self.server_listeners = nil;
	
	timerThread = [[NSThread alloc] initWithTarget:self selector:@selector(startTimerThread) object:nil]; //Create a new thread
    [timerThread start]; //start the thread
	
	NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"MainCell" owner:self options:nil];
    self.cell_for_height = (MainCell *)[nib objectAtIndex:0];
	nib = nil;
    
    self.mustStop = NO;
	
	return self;
	
}

-(void) clearAll {
	self.comments = nil;
	[self.tableView reloadData];
}

-(void) doPause {
	if (self.timer_REQ) {
		if ([self.timer_REQ isValid]) {
			[self.timer_REQ invalidate];
		}
		self.timer_REQ = nil;
	}
}

-(void) doResume {
	if (!self.timer_REQ) {
		timerThread = [[NSThread alloc] initWithTarget:self selector:@selector(startTimerThread) object:nil]; //Create a new thread
		[timerThread start]; //start the thread
	}
}

-(void)startTimerThread {
	
    NSAutoreleasePool *timerNSPool = [[NSAutoreleasePool alloc] init];
    NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
    
    self.timer_REQ = [NSTimer scheduledTimerWithTimeInterval: 6.0
                                                      target: self
                                                        selector: @selector(refreshComments:)
                                                        userInfo: nil
                                                         repeats: YES];
	
	[runLoop addTimer:self.timer_REQ forMode:NSDefaultRunLoopMode];
	
	[runLoop run];
    [timerNSPool release];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [comments count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	
    static NSString *CellIdentifier = @"MainCell";
	
    cell = ((MainCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier]);
    if (cell == nil) {

		// We load the cell from the XIB file (MainCell.xib)
		[[NSBundle mainBundle] loadNibNamed:@"MainCell" owner:self options:nil];
		// NSLog(@"Created Cell...cell");
		
		if(is_for_broadcast) {
			cell.username.textColor = [UIColor colorWithRed:44/256.0 green:87/256.0 blue:157/256.0 alpha:1.0];
			cell.txt.textColor      = [UIColor whiteColor];
		}

	}
	
	@try {
		
		NSString *c = [[comments objectAtIndex:indexPath.row] objectForKey:@"text"];
		NSString *u = [[comments objectAtIndex:indexPath.row] objectForKey:@"username"];
	
		[cell txt].font      = [UIFont fontWithName:@"Arial" size:14.0];
		[cell username].font = [UIFont fontWithName:@"Arial" size:14.0];

		// We put the colored username on top of the non-colored
		[[cell txt] setText:[NSString stringWithFormat:@"%@: %@", u, c]];
		[[cell username] setText:[NSString stringWithFormat:@"%@:", u]];
		
		//NSLog(@"%@,%@",cell.txt.text,cell.username.text);
		
		
	} @catch (NSException *exception) {
		
		NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
		return nil;
		
	}
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSString *c = [[comments objectAtIndex:indexPath.row] objectForKey:@"text"];
	NSString *u = [[comments objectAtIndex:indexPath.row] objectForKey:@"username"];
	
	//WARN: 
	// We cannot use dequeue here, because it burns the rehuse list!!!
	[cell_for_height txt].font = [UIFont fontWithName:@"Arial" size:14.0];
	[[cell_for_height txt] setText:[NSString stringWithFormat:@"%@: %@", u, c]];
	
	CGSize constraint = CGSizeMake(self.tableView.frame.size.width, 20000.0f);
	
	CGSize size = [[cell_for_height txt].text sizeWithFont:[UIFont fontWithName:@"Arial" size:14.0] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
			
	// We return the content size (instead of the frame)
	return size.height + 7;
	
}

/*
 * This method refresh comments (will be triggered with a timer)
 */
- (void) refreshComments:(NSTimer *)theTimer {
	NSLog(@"Refresh Queries");

	if (self.mustStop) {
        [theTimer invalidate];
        return;
    }

    if(self.bcast_id) {
			
        // We can push new comments to the top of the list
        // ... and to the top of the view		
        self.comments = [fi get_comments:self.bcast_id];
			
        if (self.comments) {
            [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
        }
			
        NSString *listeners_tmp = [fi get_live_listeners:self.bcast_id];
			
        if (listeners_tmp) {
            self.server_listeners = [NSString stringWithFormat:@"Listeners: %@", listeners_tmp];
            [self performSelectorOnMainThread:@selector(reloadListeners) withObject:nil waitUntilDone:YES];
        }
			
        listeners_tmp = nil;
    }

}

- (void) reloadListeners {
	if (self.server_listeners) {
		self.listeners.text = self.server_listeners;
	}
}	

- (void)dealloc {
	NSLog(@"Comments controller dealloc");
    
	[fi release];
	if (self.comments) [comments release];
    [self.cell_for_height release];
    [super dealloc];
}


@end
