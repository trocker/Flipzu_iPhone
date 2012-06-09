//
//  PlayerViewController.h
//  flipzu
//
//  Created by Lucas Lain on 6/10/11.
//  Copyright 2011 Flipzu.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HJObjManager.h"
#import "HJManagedImageV.h"
#import "CommentsControllerPlayer.h"
#import "AutoScrollLabel.h"

@class flipzuAppDelegate;
@class AudioStreamer;


@interface PlayerViewController : UIViewController {
	IBOutlet UILabel					* usernameView;
	IBOutlet AutoScrollLabel			* descriptionView;
	IBOutlet UILabel					* time_strView;
	IBOutlet UILabel					* listenersView;
	IBOutlet UIImageView				* pimage;
	IBOutlet UIImageView				* bg_post_comment;	
	IBOutlet UIImageView				* arrow_comments;	
	IBOutlet UILabel					* label_comments;	
	IBOutlet UIButton					* playButton;
	IBOutlet UIImageView				* live;
	IBOutlet CommentsControllerPlayer	* comment_controller;
	IBOutlet UITextField				* comment_txt;
	IBOutlet UIActivityIndicatorView	* spinner;


	FlipInterface			   *  fi;
	NSString				   *  listeners;
	NSString				   *  username;
	NSString                   *  description;
	NSString                   *  time_str;
	NSString	               *  img_url;
	HJObjManager               *  objMan;
	HJManagedImageV            *  mimg;
	AudioStreamer              *  streamer;
	NSString		           *  to_play_url;
	NSString		           *  audio_url;
	NSString		           *  audio_url_fallback;
	NSString		           *  liveaudio_url;
	NSString		           *  previous_audio_url;
	NSString                   *  is_live;
	long					      bcast_id;
}

@property (nonatomic, retain)   NSString				    * img_url;
@property (nonatomic, retain)   NSString				    * listeners;
@property (nonatomic, retain)   NSString				    * to_play_url;
@property (nonatomic, retain)   NSString				    * audio_url;
@property (nonatomic, retain)   NSString				    * audio_url_fallback;
@property (nonatomic, retain)   NSString				    * liveaudio_url;
@property (nonatomic, retain)   NSString				    * is_live;
@property (nonatomic, retain)   NSString				    * previous_audio_url;
@property (nonatomic, retain)   NSString					* username;
@property (nonatomic, retain)   NSString					* description;
@property (nonatomic, retain)   NSString					* time_str;
@property (nonatomic, retain)   HJObjManager				* objMan;
@property (nonatomic, retain)   HJManagedImageV				* mimg;
@property (nonatomic, retain)   AudioStreamer				* streamer;
@property (nonatomic, retain)   FlipInterface               * fi;

@property (nonatomic, assign)   long						bcast_id;



- (IBAction) BackButtonClicked:(id)sender;
- (IBAction) PlayPauseButtonClicked:(id)sender;
- (IBAction) PostComment:(id)sender;
- (void)     createStreamer;
- (void)     destroyStreamer;
- (void)	 setButtonImage:(UIImage *)image;
- (void)     spinButton;
- (void)	 tryRecordedBroadcast;
- (void)	 showCommentsHelper;

@end
