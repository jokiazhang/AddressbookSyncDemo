//
//  AppDelegate.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 23/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

#import "MasterViewController.h"
#import "ContactSyncHandler.h"
#import <TFAddressBook/TFABAddressBook.h>
#import "Contact.h"
#import "CoreDataController.h"

@interface AppDelegate ()
@property (strong) ContactSyncHandler *contactSyncHandler;
@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize contactSyncHandler = _contactSyncHandler;
@synthesize coreDataController = _coreDataController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	
	_contactSyncHandler = [[ContactSyncHandler alloc] init];
	_coreDataController = [[CoreDataController alloc] init];

    // Override point for customization after application launch.
	MasterViewController *controller = nil;
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
	    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
	    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
	    splitViewController.delegate = (id)navigationController.topViewController;
	    
	    UINavigationController *masterNavigationController = [splitViewController.viewControllers objectAtIndex:0];
	    controller = (MasterViewController *)masterNavigationController.topViewController;
	} else {
	    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
		controller = (MasterViewController *)navigationController.topViewController;
	}

	controller.managedObjectContext = self.coreDataController.mainThreadContext;
	AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    [[NSNotificationCenter defaultCenter] addObserver:controller
                                             selector:@selector(reloadFetchedResults:)
                                                 name:NSPersistentStoreCoordinatorStoresDidChangeNotification
                                               object:appDelegate.coreDataController.psc];
    [[NSNotificationCenter defaultCenter] addObserver:controller
                                             selector:@selector(reloadFetchedResults:)
                                                 name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                               object:appDelegate.coreDataController.psc];

	[TFAddressBook sharedAddressBook];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactUpdated:) name:kTFDatabaseChangedExternallyNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactUpdated:) name:kTFDatabaseChangedNotification object:nil];

	[_coreDataController loadPersistentStores];

    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[self saveMainContext];
}

- (void)saveMainContext {
    NSManagedObjectContext *mainThreadMOC = self.coreDataController.mainThreadContext;
    [mainThreadMOC performBlock:^{
        if ([mainThreadMOC hasChanges]) {
            NSError *error = nil;
            if (![mainThreadMOC save:&error]) {
                NSLog(@"Error saving: %@", error);
                abort();
            }
        }
    }];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [_coreDataController applicationResumed];
}


#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

-(void)contactUpdated:(NSNotification *)notification {
	
	for (NSString *recordId in [[notification userInfo] objectForKey:kTFUpdatedRecords]) {
		Contact *contact = (Contact *)[Contact findContactForRecordId:recordId];
		if (contact) {
			NSLog(@"Our contact has been updated");
			[contact updateManagedObjectWithAddressbookRecordDetails];
		}
	}
	
	for (NSString *recordId in [[notification userInfo] objectForKey:kTFDeletedRecords]) {
		Contact *contact = (Contact *)[Contact findContactForRecordId:recordId];
		if (contact) {
			NSLog(@"Our contact has been removed from the addressbook");
			[contact updateManagedObjectWithAddressbookRecordDetails];
		}
	}
}

@end
