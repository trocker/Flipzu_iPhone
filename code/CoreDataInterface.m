//
//  CoreDataInterface.m
//  flipzu
//
//  Created by Lucas Lain on 6/6/10.
//  Copyright 2010 Flipzu.com. All rights reserved.
//

#import "CoreDataInterface.h"


@implementation CoreDataInterface

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
    
    if (managedObjectContext_ != nil) {
        return managedObjectContext_;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext_ = [[NSManagedObjectContext alloc] init];
        [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext_;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel_ != nil) {
        return managedObjectModel_;
    }
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"flipzu" ofType:@"mom"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];  
	
    return managedObjectModel_;
}

/**
 Returns the path to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (persistentStoreCoordinator_ != nil) {
        return persistentStoreCoordinator_;
    }
	
    NSURL *storeURL = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"flipzu.sqlite"]];
    
    NSError *error = nil;
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@. Trying to regenerate DB.", error, [error userInfo]);
		
		[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
		
		// We try again (for data regeneration)
		if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		} else {
			NSLog(@"Data regenerated");
		}
		
    }
    
    return persistentStoreCoordinator_;
}


- (bool)save_user :(ValueUser *)user_to_save
{
	User *u = (User *)[NSEntityDescription insertNewObjectForEntityForName:@"User" 
													inManagedObjectContext:[self managedObjectContext]];
	
	[u setToken:user_to_save.token];
	[u setUsername:user_to_save.username];
	[u setPassword:user_to_save.password];
	[u setHas_twitter:user_to_save.has_twitter];
	[u setHas_facebook:user_to_save.has_facebook];
	[u setIs_premium:user_to_save.is_premium];
		
	NSError *error;
	if (![managedObjectContext_ save:&error]) {
		NSLog(@"Cannot save user");
		return FALSE;
	} else {
		NSLog(@"User Saved");
		return TRUE;
	}

}

- (ValueUser *)new_current_user
{
	ValueUser *vu = nil;
	User *u = nil;

	//return nil;
	NSFetchRequest *request     = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:[self managedObjectContext]];
	NSPredicate *predicate      = [NSPredicate predicateWithFormat:@"token != NULL"];

	[request setEntity:entity];
	[request setPredicate:predicate];

	NSError *error;
	NSMutableArray *mutableFetchResults = [[[self managedObjectContext] executeFetchRequest:request error:&error] mutableCopy];
	u = [mutableFetchResults lastObject];
	
	if (u == nil) {
		NSLog(@"Cannot get user");
	} else {
		vu = [[ValueUser alloc] init];
		
		vu.token = u.token;
		vu.username = u.username;
		vu.password = u.password;
		vu.has_twitter = u.has_twitter;
		vu.has_facebook = u.has_facebook;
		vu.is_premium = u.is_premium;

	}

	// Free variables
	[mutableFetchResults release];
	[request release];
	return vu;
}

- (bool)delete_user
{
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:[self managedObjectContext]];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"token != NULL"];
	
	[request setEntity:entity];
	[request setPredicate:predicate];
	
	NSError *error;
	NSMutableArray *mutableFetchResults = [[[self managedObjectContext] executeFetchRequest:request error:&error] mutableCopy];
		
	User *u = [mutableFetchResults lastObject];
	
	[mutableFetchResults release];
	[request release];
	
	[[self managedObjectContext] deleteObject:u];

	// Commit the change.
	if (![[self managedObjectContext] save:&error]) {
		NSLog(@"Cannot delete user");
		return FALSE;
	} else {
		NSLog(@"User deleted");
		return TRUE;
	}

	
}

- (void)dealloc {
	[managedObjectContext_ release];
	[managedObjectModel_ release];
	[persistentStoreCoordinator_ release];
	[super dealloc];
}


@end
