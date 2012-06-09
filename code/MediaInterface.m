//
//  MediaInterface.m
//  flipzu
//
//  Created by Lucas Lain on 6/8/10.
//  Copyright 2010 Flipzu.com. All rights reserved.
//

#import "MediaInterface.h"

@implementation MediaInterface

@synthesize timer;
@synthesize mustStop;
@synthesize forceStop;
@synthesize already_started;
@synthesize toread;
@synthesize datasent;
@synthesize sockfd;
@synthesize already_auth;
@synthesize cached_key;
@synthesize cached_mediahost;
@synthesize cached_mediaport;

#define BITS_SEC 4096 // 4K per sec for AAC
#define MAX_SECONDS_DELAY 15 // TODO this should be 10;


- (id)init
{		
	NSLog(@"MediaInterface alloc");

	self.mustStop = FALSE;
	self.forceStop = FALSE;
	
	self.datasent = 0;
	self.toread = 0;
	self.sockfd = 0;
	self.already_auth = 0;
	

	self.timer = [NSTimer scheduledTimerWithTimeInterval: 5.0
												  target: self
												selector: @selector(refreshPercentage:)
												userInfo: nil
												 repeats: YES];
	
	return self;
}

-(void)startNetworkThread {

	NSLog(@"Will get data from file");
		
	// Searching for documents directory for our App
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];	
	
	char buff[65536];
	
	do {

		if(sockfd > 0) {
			int to_send = toread - datasent;
			
			if (to_send != 0) {
				
				NSString *file = [documentsDirectory stringByAppendingPathComponent:cached_key];
				
				int fd = 0;

				fd = open([file UTF8String],O_RDONLY);

				if (fd) {
				
					lseek(fd,datasent,SEEK_SET); //We move to the bytes already sent
					int readed = read(fd,&buff, 65535);
					
					close(fd);
					
					// ... Send the bytes
					ssize_t databytes = send(sockfd, buff, readed, 0);

					if(databytes > -1) {
						// NSLog(@"sent bytes: %d",databytes);

						datasent += databytes;
						self.already_started = YES;

					} else {
						NSLog(@"Must Reconnect");
						self.sockfd = 0;
					}
					
					//NSLog(@"STATUS: %ld",self.toread - self.datasent);
					
				} else {
					perror("Error reading cache file");
				}
			}
		} else if (self.already_started) {
			NSLog(@"Not connected");
			if ([self doConnect:cached_key :cached_mediahost :cached_mediaport] == -1) {
				self.sockfd = 0;
			};
		}
		
		usleep(100000);
		
	} while (    ((!mustStop) 
			     ||  ((toread - datasent) > 0)) 
			 &&  (!forceStop)); 

	if (sockfd) {
		close(sockfd);
	}
	
}

- (int) recv_auth {

	int bcast_id=-1;
	char buff[40];
	int n = 0;
	
	n = read(sockfd,buff,40);

	if(n < 1) {
		perror("Could not read socket auth");
		return -1;
	}

	buff[n]='\0';

	NSString *auth = [NSString stringWithFormat:@"%s",buff];
		
	NSArray *chunks = [auth componentsSeparatedByString:@" "];

	@try {
	
		NSString *result = [chunks objectAtIndex:1];
	
		if ([result isEqualToString:@"OK"]) {
		
			NSLog(@"AUTH OK");
		
			NSString *bcid = [chunks objectAtIndex:2];
		
			bcast_id = [bcid intValue];
	
		} else {
			NSLog(@"Response: %@",auth);
		}

		
	} @catch (id theException) {
		NSLog(@"Parse failed. Exception: %@. Server response: %@", theException, auth);
	}

	return bcast_id;
}

- (int)doConnect:(NSString *)key
				:(NSString *)mediahost
				:(NSString *)mediaport
{
	struct sockaddr_in addr;
	
	int bcast_id = 0;
	
    // Create a socket
    sockfd = socket( AF_INET, SOCK_STREAM, 0 );
	
	// TODO: For testing purposes
	// mediahost = @"200.42.0.108";
	
	struct hostent *server = gethostbyname([mediahost UTF8String]);

	int conn = 0;
	
	if (server != NULL) {

		struct in_addr **addr_list = (struct in_addr **)server->h_addr_list;

		printf("Connecting to : %s:%d\n", inet_ntoa(*addr_list[0]),[mediaport intValue]);
	
		addr.sin_family = AF_INET;
		addr.sin_addr = *addr_list[0];
		addr.sin_port = htons([mediaport intValue]);
	
		conn = connect(sockfd, ((struct sockaddr *)&addr), sizeof(addr)); 
		
	}
	
	if (conn == 0) {
		
		NSLog(@"Connected to Estela: %@:%@",mediahost, mediaport);
		
		// Setting to ignore sigpipe ... but we can reconnect
		int set = 1;
		setsockopt(sockfd, SOL_SOCKET, SO_NOSIGPIPE, (void *)&set, sizeof(int));
		
		NSString *newkey = [NSString stringWithFormat:@"%s\n",[key UTF8String]];
		
		const char *key_str = [newkey UTF8String];
		int key_size = strlen([newkey UTF8String]);

		send(sockfd, key_str, key_size, 0);
		
		bcast_id = [self recv_auth];
		
		self.cached_key = key;
		self.cached_mediahost = mediahost;
		self.cached_mediaport = mediaport;
		
	} else {

		perror("Socket");
		
		return -1;
		
	}
	
	already_auth = 1;
	
	return bcast_id;
}


- (void) refreshPercentage:(NSTimer *)theTimer {
	
	// THIS WILL FINALLY CALL THE "DEALLOC" METHOD
	// because the target set in NSTimer, increments the retain count of this class
	if(mustStop == TRUE) {
			
		[theTimer invalidate];
		
	} else {
		
		// We check the PROGRESS STATUS. 
		
		if(toread - datasent > BITS_SEC * MAX_SECONDS_DELAY
		   && bw_alerted == NO) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Your internet connection is slow :(" 
															message:@"Your listeners might experience silence periods" 
														   delegate:nil  
												  cancelButtonTitle:@"Stay live!" 
												  otherButtonTitles:nil];
			
			[alert show];
			[alert release];
			
			bw_alerted = YES ;
			// WE can send NEEDBW notification to RecController
			// [theTimer invalidate];
			// [[NSNotificationCenter defaultCenter] postNotificationName:@"NEEDBW" object:nil];
		}
		
		
		// TODO: Add a notification for "crappy connection"

	}
}

- (void)dealloc {
	NSLog(@"MediaInterface dealloc");
	[super dealloc];
}

@end
