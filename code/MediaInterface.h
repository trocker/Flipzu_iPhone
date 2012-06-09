//
//  MediaInterface.h
//  flipzu
//
//  Created by Lucas Lain on 6/8/10.
//  Copyright 2010 Flipzu.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <netdb.h>
#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>

@interface MediaInterface : NSObject {
	Boolean						mustReconnect;
	NSTimer *					timer;
	BOOL						mustStop;
	BOOL						forceStop;
	BOOL						already_started;
	int							sockfd;
	int							already_auth;

	long						datasent;
	long						toread;
	BOOL						bw_alerted;
	
	NSString*					cached_key;
	NSString*					cached_mediahost;
	NSString*					cached_mediaport;




}

@property (nonatomic, assign)   NSTimer			*timer;
@property (nonatomic, assign)   BOOL			mustStop;
@property (nonatomic, assign)   BOOL			forceStop;
@property (nonatomic, assign)   BOOL			already_started;
@property (nonatomic, assign)   long			datasent;
@property (nonatomic, assign)   long			toread;
@property (nonatomic, assign)   int 			sockfd;
@property (nonatomic, assign)   int 			already_auth;
@property (nonatomic, assign)   NSString		*cached_key;
@property (nonatomic, assign)   NSString		*cached_mediahost;
@property (nonatomic, assign)   NSString		*cached_mediaport;


- (int)doConnect:(NSString *)key
				:(NSString *)mediahost
                :(NSString *)mediaport;

- (void)startNetworkThread ;

@end
