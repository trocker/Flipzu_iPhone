//
//  CoreDataInterface.h
//  flipzu
//
//  Created by Lucas Lain on 6/6/10.
//  Copyright 2010 Flipzu.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "User.h"
#import "ValueUser.h"

@interface CoreDataInterface : NSObject {
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
}

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSString *)applicationDocumentsDirectory;


// User related queries
- (bool)save_user :(ValueUser *)user_to_save;
- (ValueUser *)new_current_user;
- (bool)delete_user;

@end
