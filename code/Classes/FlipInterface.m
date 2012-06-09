//
//  FlipInterface.m
//  flipzu
//
//  Created by Lucas Lain on 5/24/10.
//  Copyright 2010 Flipzu. All rights reserved.
//

#import "FlipInterface.h"


@implementation FlipInterface

NSString * const host_def   = @"http://flipzu.com";
NSString * const host_stats = @"http://stats.flipzu.com";
NSString * const host_login = @"https://flipzu.com";

// TODO: Just in case
//NSString * const host_def = @"http://10.0.0.10";
//NSString * const host_stats = @"http://stats.flipzu.com";
//NSString * const host_login = @"https://10.0.0.10";

-(ValueUser *)user {
	if(user != nil) {
		return user;
	} else {
		user = [ci new_current_user];
		return user;
	}
}

-(NSString *)mediahost {
	return mediahost;
}

-(NSArray *) do_call:(NSString *)host
                    :(NSString *)requested_path {
	
	// make a synchronous HTTP request to your API
	NSURL *url = [NSURL URLWithString:[host stringByAppendingString:requested_path]]; 
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	NSURLResponse *response;
	NSError *error;
	NSData *plistData;
	plistData = [NSURLConnection sendSynchronousRequest:request
									  returningResponse:&response
												  error:&error ];
	
	// parse the HTTP response into a plist
	NSPropertyListFormat format;
	id plist = nil;
	NSString *errorStr;
			
	if (plistData) {
		plist = [NSPropertyListSerialization propertyListFromData:plistData
											 mutabilityOption:NSPropertyListImmutable
													   format:&format
											 errorDescription:&errorStr];
						
		if(!plist) {
			NSLog(@"Error parsing: %@", errorStr);
		}
		
	} else {
		NSLog(@"Error in WS:%@",error);
	}

	
	return plist;
	
}

-(void) do_post:(NSString *)requested_path
			   :(NSData *)body {
	
	// make a synchronous HTTP request to your plist API
	NSURL *url = [NSURL URLWithString:[host_login stringByAppendingString:requested_path]]; 
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
										   
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:body];
	[request setTimeoutInterval:10.0];
		
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request
																  delegate:self
														  startImmediately:YES];
	
	[connection start];
	
	[connection release];
	
}

-(id) do_sync_post:(NSString *)requested_path
					:(NSData *)body {
	
	// make a synchronous HTTP request to your plist API
	NSURL *url = [NSURL URLWithString:[host_def stringByAppendingString:requested_path]]; 
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:body];
	[request setTimeoutInterval:1];
	
	NSURLResponse *response;
	NSError *error;
	
	NSData *plistData;
	plistData = [NSURLConnection sendSynchronousRequest:request
									  returningResponse:&response
												  error:&error ];
		 
	// parse the HTTP response into a plist
	NSPropertyListFormat format;
	id plist = nil;
	NSString *errorStr;
	 
	if (plistData) {
		plist = [NSPropertyListSerialization propertyListFromData:plistData
												 mutabilityOption:NSPropertyListImmutable
														   format:&format
												 errorDescription:&errorStr];
		if(!plist) {
			NSLog(@"%@: %s", errorStr, [plistData bytes]);
		}
	 
	} else {
		NSLog(@"Error in WS:%@",error);
	}
	 
	return plist;
	 
	
}

-(void) do_fb_login :(NSString *)access_token {
	[self do_login:@"fb_access_token" :access_token];
}

-(void) do_tw_login :(NSString *)access_token {
	
	[self do_login:@"tw_access_token" :access_token];
	
}
	
-(void) do_login	:(NSString *)param
					:(NSString *)access_token {


	NSData *body = [[NSString stringWithFormat:@"%@=%s",param,[access_token UTF8String]] dataUsingEncoding:NSUTF8StringEncoding];
	
    NSLog(@"QUERY STR: %@",[NSString stringWithFormat:@"%@=%s",param,[access_token UTF8String]]);
    
	[self do_post :@"/api/request_token_with_token.plist"
				  :body];

}

-(bool) already_validated
{
	ValueUser *u = [ci new_current_user];
	if(u) {
		user = u;
		return TRUE;
	} else {
		return FALSE;
	}

}

/* 
 * this function brings all live comments locally
 */
-(NSArray *) get_comments :(long)bcast_id {
	NSArray *comments = nil;
		
	NSString *url = [NSString stringWithFormat:@"/api/get_comments.plist/%d",bcast_id];
	
	//NSLog(@"URL: %@",url);
	
	@try {
		
		id plist = [self do_call :host_def :url];
				
		if (plist) {
			comments = (NSArray *)[plist objectForKey:@"comments_list"];
		}
		
	} @catch (NSException *exception) {
		
		NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
		
	}
	
	return comments;
	
}

/*
 * This method request the timeline
 */
-(NSMutableArray *) get_timeline :(int)list {
				
	NSMutableArray *broadcasts = nil;

	NSData *body = [[NSString stringWithFormat:@"access_token=%@&list=%d",
					 [self user].token,
					 list
					 ] 
					dataUsingEncoding:NSUTF8StringEncoding];
	
	id plist = [self do_sync_post :@"/api/get_timeline.plist"
							      :body];
			
	if (plist) {
		
		if ([@"NOK" isEqualToString:[plist objectForKey:@"status"]]) {
			// Error on request Key
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Expired session" 
															message:@"You need to relogin to this application" 
														   delegate:self 
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];
			[alert show];
			[alert release];
		} else {
			broadcasts = (NSMutableArray *)[plist objectForKey:@"timeline"];
		}
		
	} 
	
	return broadcasts;
}

/*
 * This method posts a comments
 */
-(BOOL) post_comment :(NSString *)comment_txt :(long)bid {
		
	NSData *body = [[NSString stringWithFormat:@"access_token=%@&comment_txt=%@",
					 [self user].token,
					 comment_txt
					 ] 
					dataUsingEncoding:NSUTF8StringEncoding];
	
	NSString *url = [NSString stringWithFormat:@"/api/post_comment.plist/%d", bid];
		
	id plist = [self do_sync_post :url
							      :body];
	
	// NSLog(@"%@",plist);
	
	if (plist) {
		return YES;
	} else {
		return NO;
	}

}

/* 
 * this function brings all live comments locally
 */
-(NSString *) get_live_listeners:(int)bcast_id {
		
	NSString *url = [NSString stringWithFormat:@"/stats?bcast_id=%d",bcast_id];
	
	NSString *listeners = nil;
		
	@try {

		id plist = [self do_call :host_stats :url];
				
		if (plist) {
			listeners = [plist objectForKey:@"listening"];
		}
		
	} @catch (NSException *exception) {
		NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
	}
	
	return listeners;
	
}


/*
 * This method request a new key for broadcast
 */
-(ResponseKey *) new_key :(NSString *)title
                                 :(bool)tw_share 
								 :(bool)fb_share {

	ValueUser *c_user = [self user];
	
	ResponseKey *responseKey = [[ResponseKey alloc] init];

	NSString *access_token = [c_user token];
	
	
	if (title == nil) {
		title = [NSString stringWithFormat:@""];
	}
	
	NSData *body = [[NSString stringWithFormat:@"access_token=%@&text=%@&app_id=2&tw_share=%d&fb_share=%d",
					 access_token,
					 title,
					 tw_share,
					 fb_share] 
					dataUsingEncoding:NSUTF8StringEncoding];

	id plist = [self do_sync_post :@"/api/request_key.plist"
							      :body];
		
	if (plist) {
		
		NSString *token = [(NSString *)[plist objectForKey:@"key"] copy];
		
		if (!token) {
			[responseKey setStatus:@"NOK"];
			[responseKey setMessage:@"Invalid credentials. You need to Relogin."];
		} else {
			[responseKey setStatus:@"OK"];
			[responseKey setKey:token];
			[responseKey setMediahost:(NSString *)[plist objectForKey:@"server_name"]];
			[responseKey setMediaport:(NSString *)[plist objectForKey:@"server_port"]];
		}
		
		[token release];
		
	} else {
		[responseKey setStatus:@"NOK"];
		[responseKey setMessage:@"Check your internet connection"];
	}
			
	return responseKey;
}

// CALLBACKS FOR SSL
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	
	NSLog(@"Can AUTH?");
	
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

// CALLBACK FOR SSL
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	
	NSLog(@"Challenge called");

	[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
	
	[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];	
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    //[connection release];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"LOGINTIMEOUT" object:nil];		

}

// DATA RECEIVED FOR LOGIN
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)plistData {
	
	NSLog(@"Received data");
	
	// parse the HTTP response into a plist
	NSPropertyListFormat format;
	id plist = nil;
	NSString  *errorStr;	
	NSString  *token = nil;
	NSString  *username = nil;
	NSNumber  *has_twitter = nil;
	NSNumber  *has_facebook = nil;
	NSNumber  *is_premium = nil;
	
	plist = [NSPropertyListSerialization propertyListFromData:plistData
											 mutabilityOption:NSPropertyListImmutable
													   format:&format
											 errorDescription:&errorStr];
	if(!plist) {
		NSLog(@"Error parsing response: %@", errorStr);
	}
	
	if (plist) {
		token = (NSString *)[plist objectForKey:@"token"];
		username = (NSString *)[plist objectForKey:@"username"];
		has_twitter = (NSNumber *)[plist objectForKey:@"has_twitter"];
		has_facebook = (NSNumber *)[plist objectForKey:@"has_facebook"];
		is_premium = (NSNumber *)[plist objectForKey:@"is_premium"];
	}
	
	//NSLog(@"plist: %@",plist);
	
	if (token) {
		
		ValueUser *u = [[ValueUser alloc] init];
		
		[u setToken:token];
		[u setUsername:username];
		[u setPassword:@""];
		[u setHas_twitter:has_twitter];
		[u setHas_facebook:has_facebook];
		[u setIs_premium:is_premium];
				
		[ci save_user:u];
		
		[u release];
		
		user = [ci new_current_user];
		
		NSLog(@"Logged");

		[[NSNotificationCenter defaultCenter] postNotificationName:@"LOGINOK" object:nil];		

		
	} else {
		NSLog(@"Timeout");

	}
		
}

-(id) init
{
	if ((self = [super init])) {
		ci = [[CoreDataInterface alloc] init] ;
	}
	return self;
}

-(void)dealloc {
	NSLog(@"FlipInterface dealloc");
	if (mediahost) [mediahost release];
	[ci release];
	[user release];
	[super dealloc];
}
@end
