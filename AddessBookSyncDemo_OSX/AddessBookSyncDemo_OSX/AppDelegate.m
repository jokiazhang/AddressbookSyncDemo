//
//  AppDelegate.m
//  AddressbookSyncDemoMac
//
//  Created by Tom Fewster on 27/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "Contact.h"
#import "NSObject+BlockExtensions.h"
#import "AmbigousContactResolverViewController.h"
#import "UnresolvedContactResolverViewController.h"
#import "CoreDataController.h"

@interface AppDelegate ()
@property (strong) IBOutlet NSArrayController *tableArrayController;
@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize personView;
@synthesize contactSelectionIndex;
@synthesize arrayController;
@synthesize searchFilter;
@synthesize ambigousContactResolver;
@synthesize unresolvedContactResolver;
@synthesize selectedContact;
@synthesize coreDataController = _coreDataController;
@synthesize tableArrayController = _tableArrayController;

- (id)init {
	_coreDataController = [[CoreDataController alloc] init];
	return [super init];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

	// Insert code here to initialize your application
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveAction:) name:NSApplicationWillResignActiveNotification object:nil];
	[TFAddressBook sharedAddressBook];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactUpdated:) name:kTFDatabaseChangedExternallyNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactUpdated:) name:kTFDatabaseChangedNotification object:nil];

	[_coreDataController loadPersistentStores];

	[_tableArrayController setSortDescriptors:
	 [NSArray arrayWithObjects:
	  [[NSSortDescriptor alloc] initWithKey:@"lastName" ascending:YES],
	  nil]];
}

/**
    Returns the directory the application uses to store the Core Data store file. This code uses a directory named "AddressbookSyncDemoMac" in the user's Library directory.
 */
- (NSURL *)applicationFilesDirectory {

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *libraryURL = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    return [libraryURL URLByAppendingPathComponent:@"AddressbookSyncDemo"];
}

/**
    Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
 */
//- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
//    return [_coreDataController.mainThreadContext undoManager];
//}

/**
    Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
 */
- (IBAction)saveAction:(id)sender {
    NSError *error = nil;
    
    if (![_coreDataController.mainThreadContext commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }

    if (![_coreDataController.mainThreadContext save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    // Save changes in the application's managed object context before the application terminates.

    if (!_coreDataController.mainThreadContext) {
        return NSTerminateNow;
    }

    if (![_coreDataController.mainThreadContext commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }

    if (![_coreDataController.mainThreadContext hasChanges]) {
        return NSTerminateNow;
    }

    NSError *error = nil;
    if (![_coreDataController.mainThreadContext save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

- (void)resolveMissingContact:(Contact *)contact inAddressBook:(TFAddressBook *)addressbook {
	if (contact.addressbookCacheState == kAddressbookCacheLoadFailed) {
		NSLog(@"Contact not found");
		[unresolvedContactResolver resolveConflict:contact];
		[personView setPerson:nil];
	} else if (contact.addressbookCacheState == kAddressbookCacheLoadAmbigous) {
		NSLog(@"Contact Ambigous");
		[ambigousContactResolver resolveConflict:contact];
		[personView setPerson:nil];
	} else if (contact.addressbookCacheState == kAddressbookCacheLoaded) {
		NSLog(@"Or contact has probably been deleted since we cached it");
		[contact updateManagedObjectWithAddressbookRecordDetails];
	} else if (contact.addressbookCacheState == kAddressbookCacheCurrentlyLoading) {
		// lets try again in a 1/2 a second
		[self performBlock:^{
			[self resolveMissingContact:contact inAddressBook:addressbook];	
		} afterDelay:0.5];
	} else if (contact.addressbookCacheState == kAddressbookCacheLoaded) {
		TFRecord *record = [contact addressbookRecordInAddressBook:addressbook];
		if (record != NULL) {
			[personView setPerson:(ABPerson *)record];
		}
	}
}

- (void)setContactSelectionIndex:(NSIndexSet *)value {
	contactSelectionIndex = value;
	if (_addressbook == nil) {
		_addressbook = [TFAddressBook addressBook];
	}
	if ([contactSelectionIndex count] != 0) {
		self.selectedContact = [[_tableArrayController arrangedObjects] objectAtIndex:[contactSelectionIndex firstIndex]];
		TFRecord *record = [self.selectedContact addressbookRecordInAddressBook:_addressbook];
		if (record == NULL) {
			// Somthing is wrong, lets try to resolve it
			[self resolveMissingContact:self.selectedContact inAddressBook:_addressbook];
		} else {
			[personView setPerson:(ABPerson *)record];
		}
	} else {
		self.selectedContact = nil;
	}
}

- (NSArray *)sortDescriptors {
	return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"sortTag2" ascending:YES]];
}

- (IBAction)toggelEdit:(NSButton *)button {
	if (personView.editing) {
		personView.editing = NO;
		if ([_addressbook hasUnsavedChanges]) {
			[_addressbook save];
		}
		button.title = @"Edit";
	} else {
		personView.editing = YES;
		button.title = @"Done";
	}

	for (Contact *c in _tableArrayController.arrangedObjects) {
		NSLog(@"%@", c);
	}
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
