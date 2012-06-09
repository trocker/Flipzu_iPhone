//
//  FlipInterface.h
//  flipzu
//
//  Created by Lucas Lain on 5/24/10.
//  Copyright 2010 Flipzu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreDataInterface.h"
#import "ValueUser.h"
#import "ResponseKey.h"

@interface FlipInterface : NSObject {
	CoreDataInterface *			ci;
	ValueUser *					user;
	NSString *					mediahost;
	NSObject *					callback;
}

-(NSString *)		mediahost;
-(bool)				already_validated;
-(void)				do_fb_login	:(NSString *)access_token ;
-(void)				do_tw_login :(NSString *)access_token ;
-(void)				do_login:(NSString *)param
							:(NSString *)access_token ;

-(NSArray *)		get_comments :(long) bcast_id;

-(NSString *)		get_live_listeners:(int)bcast_id;
-(ResponseKey *)	new_key:(NSString *)title
								   :(bool)tw_share
								   :(bool)fb_share;

-(NSMutableArray *)	get_timeline :(int)list;
-(BOOL) post_comment :(NSString *)comment_txt :(long)bid;

@end
