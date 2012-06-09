//
//  RecController.h
//  flipzu
//
//  Created by Lucas Lain on 5/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AQRecorder.h"
#import "ValueUser.h"
#import "CoreDataInterface.h"
#import "FlipInterface.h"
#import "AQLevelMeter.h"
#import "CommentsController.h"
#import "Appirater.h"
#import "MediaInterface.h"

#import <UIKit/UIKit.h> 
#import <AVFoundation/AVAudioPlayer.h>

@interface RecController : NSObject {

	bool					is_live;
	CFStringRef				recordFilePath; 
	AQRecorder*				recorder;
	CoreDataInterface*		ci;
	FlipInterface*			fi;
	ValueUser*				user;
	MediaInterface * 		mi;
	NSTimer *				timer;
	long					seconds_running;

	IBOutlet UILabel*						seconds_label;
	IBOutlet UITextField*					bcast_title;
	IBOutlet UIButton*						recButton;
	IBOutlet CommentsController *			cc;
	IBOutlet AQLevelMeter*					lvlMeter_in;
	IBOutlet UIButton*						twButton;
	IBOutlet UIButton*						fbButton;
	IBOutlet UIBarButtonItem*				backButton;
    NSThread*                               networkThread;
    ResponseKey*                            responseKey;


}

@property (nonatomic, retain)   UILabel			    *seconds_label;
@property (nonatomic, retain)   UIButton			*recButton;
@property (nonatomic, retain)   UIBarButtonItem		*backButton;
@property (nonatomic, retain)   NSTimer			    *timer;
@property (readonly)            AQRecorder			*recorder;
@property (readonly)            CoreDataInterface	*ci;
@property (readonly)            FlipInterface		*fi;
@property (readonly)            MediaInterface		*mi;
@property (readonly)            ResponseKey         *responseKey;

@property (nonatomic, retain)	ValueUser			*user;

@property (nonatomic, retain, readwrite)	AQLevelMeter				*lvlMeter_in;
@property (nonatomic, retain)				CommentsController			*cc;



- (IBAction) btnRec_Clicked:(id)sender;
- (IBAction) fbButtonClicked:(id)sender;
- (IBAction) twButtonClicked:(id)sender;
- (void)     disableMeter;
- (void)     enableMeter;
- (void)     stopRecord;
- (BOOL)     isRunning;
- (void)     start_stop_rec;
- (void)     enableDisableRec;


@end
