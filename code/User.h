//
//  User.h
//  flipzu
//
//  Created by Lucas Lain on 6/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface User :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSNumber * has_twitter;
@property (nonatomic, retain) NSNumber * has_facebook;
@property (nonatomic, retain) NSNumber * is_premium;
@property (nonatomic, retain) NSString * token;

@end



