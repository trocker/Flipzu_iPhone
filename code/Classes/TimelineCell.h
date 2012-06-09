//
//  TimelineCell.h
//  flipzu
//
//  Created by Lucas Lain on 6/7/11.
//  Copyright 2011 Flipzu.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TimelineCell : UITableViewCell {
	IBOutlet UIImageView *		avatar;
	IBOutlet UIImageView *		live;
	IBOutlet UILabel     *		desc;
	IBOutlet UILabel     *		username;
	IBOutlet UILabel     *		details;
	IBOutlet UILabel	 *	    time_str;
}

@property (nonatomic, retain)   UIImageView			*avatar;
@property (nonatomic, retain)   UIImageView			*live;
@property (nonatomic, retain)   UILabel				*desc;
@property (nonatomic, retain)   UILabel  			*username;
@property (nonatomic, retain)   UILabel  			*details;
@property (nonatomic, retain)   UILabel  			*time_str;

@end
