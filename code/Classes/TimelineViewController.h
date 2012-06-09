//
//  TimelineController.h
//  flipzu
//
//  Created by Lucas Lain on 6/6/11.
//  Copyright 2011 Flipzu.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RecViewController.h"
#import "TimelineCell.h"
#import "HJObjManager.h"
#import "PlayerViewController.h"
#import "EGORefreshTableHeaderView.h"

@class flipzuAppDelegate;

@interface TimelineViewController : UIViewController <UIActionSheetDelegate, EGORefreshTableHeaderDelegate, UITableViewDelegate, UITableViewDataSource> {
                                                
	IBOutlet UIButton				 * nowPlayingButton;
	IBOutlet UITabBar				 * tabBar;

	IBOutlet UITabBarItem			 * friends_list;
	IBOutlet UITabBarItem			 * all_list;
	IBOutlet UITabBarItem			 * hot_list;
	IBOutlet UITabBarItem			 * mine_list;
	
    IBOutlet UITableView			 * tview;
	
	NSTimer							 * timer;
	IBOutlet UIActivityIndicatorView * activity;
	IBOutlet UIView					 * activity_bg;
	IBOutlet UIBarButtonItem         * go_live;
    NSMutableArray					 * broadcasts;
	FlipInterface					 * fi;	
	TimelineCell					 * cell_for_height;
	IBOutlet TimelineCell			 * cell;
	HJObjManager					 * objMan;
	PlayerViewController			 * playerView;
	IBOutlet UILabel				 * subTitle;
	IBOutlet UIButton				 * now_playing;
    EGORefreshTableHeaderView        * _refreshHeaderView;

	int								 list;

    BOOL                             _reloading;                                    
	BOOL                             playInterrupted;

}

@property (nonatomic, assign)   RecViewController				* recView;
@property (nonatomic, retain)   NSMutableArray			        * broadcasts;
@property (nonatomic, retain)   FlipInterface			        * fi;
@property (nonatomic, retain)   TimelineCell			        * cell_for_height;
@property (nonatomic, retain)   PlayerViewController            * playerView;

- (IBAction) LogoutClicked:(id)sender;
- (IBAction) NowPlayingClicked:(id)sender;
- (void)     playbackQueueResumed;
- (void)     playbackQueueStopped;
- (void)     startAudioSystem;
- (void)	 showLoading;
- (void)reloadTableViewDataSource;


-(void) addCenterButtonWithImage:(UIImage*)buttonImage 
				  highlightImage:(UIImage*)highlightImage;

- (void)setList :(int)i;



void interruptionListener(	void *	inClientData,
						  UInt32	inInterruptionState);

void propListener(	void *                  inClientData,
				    AudioSessionPropertyID	inID,
				    UInt32					inDataSize,
					const void *		    inData);

@end
