//
//  CommentsController.h
//  flipzu
//
//  Created by Lucas Lain on 5/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlipInterface.h"
#import "MainCell.h"


@class FlipInterface;
@class MainCell;

@interface CommentsController : UITableViewController {
	NSArray *					comments;
	FlipInterface *				fi;
	NSTimer *					timer_REQ;
	IBOutlet MainCell *			cell;
	IBOutlet UILabel*			listeners;
	NSThread*					timerThread;
	long						bcast_id;
	NSString*					server_listeners;
	MainCell*					cell_for_height;
	BOOL						is_for_broadcast;
    BOOL                        mustStop;
}

@property (nonatomic, retain)   NSArray			*comments;
@property (nonatomic, retain)   FlipInterface	*fi;
@property (nonatomic, retain)   UILabel			*listeners;
@property (nonatomic, retain)   NSString		*server_listeners;
@property (nonatomic, retain)   MainCell		*cell_for_height;
@property (nonatomic, assign)   NSTimer			*timer_REQ;
@property (nonatomic, assign)   long			bcast_id;
@property (nonatomic, assign)   BOOL			is_for_broadcast;
@property (nonatomic, assign)   BOOL			mustStop;



- (void) refreshComments:(NSTimer *)theTimer;
- (void) doPause;
- (void) doResume;
- (void) reloadListeners;
- (void) clearAll;

@end
