//
//  MainCell.h
//  flipzu
//
//  Created by Lucas Lain on 6/5/10.
//  Copyright 2010 Flipzu.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MainCell : UITableViewCell {
	IBOutlet UIImageView *		img;
	IBOutlet UIImageView *		img_bottom;
	IBOutlet UITextView *	txt;
	IBOutlet UITextView *	username;
	IBOutlet UILabel *	time_ago;
}

@property (nonatomic, retain)   UIImageView			*img;
@property (nonatomic, retain)   UIImageView			*img_bottom;
@property (nonatomic, retain)   UITextView		*txt;
@property (nonatomic, retain)   UITextView 		*username;
@property (nonatomic, retain)   UILabel 		*time_ago;

@end
