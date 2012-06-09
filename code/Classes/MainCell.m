//
//  MainCell.m
//  flipzu
//
//  Created by Lucas Lain on 6/5/10.
//  Copyright 2010 Flipzu.com. All rights reserved.
//

#import "MainCell.h"


@implementation MainCell

@synthesize img,txt,username,time_ago,img_bottom;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)dealloc {
    [super dealloc];
}


@end
