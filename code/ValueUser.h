//
//  ValueUser.h
//  flipzu
//
//  Created by Lucas Lain on 7/7/10.
//  Copyright 2010 Flipzu.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ValueUser : NSObject {
	NSString *token;
	NSString *username;
	NSString *password;
	NSNumber *has_twitter;
	NSNumber *has_facebook;
	NSNumber *is_premium;
}

@property (nonatomic, retain) NSString  * token;
@property (nonatomic, retain) NSString  * username;
@property (nonatomic, retain) NSString  * password;
@property (nonatomic, retain) NSNumber  * has_twitter;
@property (nonatomic, retain) NSNumber  * has_facebook;
@property (nonatomic, retain) NSNumber  * is_premium;

@end
