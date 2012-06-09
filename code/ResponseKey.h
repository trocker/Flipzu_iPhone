//
//  ResponseKey.h
//  flipzu
//
//  Created by Lucas Lain on 11/3/10.
//  Copyright 2010 Flipzu.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ResponseKey : NSObject {
	NSString *key;
	NSString *status;
	NSString *message;
	NSString *mediahost;
	NSString *mediaport;
}

@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * mediahost;
@property (nonatomic, retain) NSString * mediaport;

@end