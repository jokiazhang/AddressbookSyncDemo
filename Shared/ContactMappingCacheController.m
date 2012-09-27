//
//  ContactMappingCacheController.m
//  AddressBookSyncDemo_OSX
//
//  Created by Tom Fewster on 23/08/2012.
//  Copyright (c) 2012 Tom Fewster. All rights reserved.
//

#import "ContactMappingCacheController.h"
#import "Contact.h"
#import "ContactMapping.h"

@implementation ContactMappingCacheController

+ (ContactMappingCacheController *)sharedInstance {
	static dispatch_once_t onceToken = 0;
	__strong static id _sharedObject = nil;
	dispatch_once(&onceToken, ^{
		_sharedObject = [[ContactMappingCacheController alloc] init];
	});
	return _sharedObject;
}

- (TFRecordID)identifierForContact:(Contact *)contact {
	NSURL *uri = [[contact objectID] URIRepresentation];
	
	__block TFRecordID result = nil;
	[MANAGED_OBJECT_CONTEXT performBlockAndWait:^{
		NSSet *results = [MANAGED_OBJECT_CONTEXT fetchObjectsForEntityName:@"ContactMapping" withPredicate:[NSPredicate predicateWithFormat:@"contactURI == %@", uri]];
		if ([results count]) {
			result = ((ContactMapping *)[results anyObject]).addressbookReference;
		}
	}];
	return result;
}

- (void)setIdentifier:(TFRecordID)identifier forContact:(Contact *)contact {
	if ([[contact objectID] isTemporaryID]) {
		WarningLog(@"Can't save Contact mapping, contact is only temporary");
		return;
	}

	NSURL *key = [[contact objectID ] URIRepresentation];

	[MANAGED_OBJECT_CONTEXT performBlock:^{
		NSSet *results = [MANAGED_OBJECT_CONTEXT fetchObjectsForEntityName:@"ContactMapping" withPredicate:[NSPredicate predicateWithFormat:@"contactURI == %@", key]];
		if ([results count]) {
			ContactMapping *mapping = [results anyObject];
			mapping.addressbookReference = identifier;
		} else {
			ContactMapping *mapping = [NSEntityDescription insertNewObjectForEntityForName:@"ContactMapping" inManagedObjectContext:MANAGED_OBJECT_CONTEXT];
			mapping.contactURI = key;
			mapping.addressbookReference = identifier;
		}
	}];
}

- (void)removeIdentifierForContact:(Contact *)contact {
	NSURL *uri = [contact.objectID URIRepresentation];
	
	[MANAGED_OBJECT_CONTEXT performBlockAndWait:^{
		NSSet *results = [MANAGED_OBJECT_CONTEXT fetchObjectsForEntityName:@"ContactMapping" withPredicate:[NSPredicate predicateWithFormat:@"contactURI == %@", uri]];
		if ([results count]) {
			[MANAGED_OBJECT_CONTEXT deleteObject:[results anyObject]];
		}
	}];
}

- (BOOL)contactExistsForIdentifier:(TFRecordID)identifier {
	__block BOOL result = NO;
	[MANAGED_OBJECT_CONTEXT performBlockAndWait:^{
		NSSet *results = [MANAGED_OBJECT_CONTEXT fetchObjectsForEntityName:@"ContactMapping" withPredicate:[NSPredicate predicateWithFormat:@"addressBookReference == %@", identifier]];
		result = ([results count] != 0);
	}];

	return result;
}

- (Contact *)contactObjectForIdentifier:(TFRecordID)identifier {
	__block Contact *result = nil;
	[MANAGED_OBJECT_CONTEXT performBlockAndWait:^{
		NSSet *results = [MANAGED_OBJECT_CONTEXT fetchObjectsForEntityName:@"ContactMapping" withPredicate:[NSPredicate predicateWithFormat:@"addressbookReference == %@", identifier]];
		if ([results count] != 0) {
			ContactMapping *mapping = [results anyObject];
			if (mapping.contactURI) {
				NSManagedObjectID *objectId = [[MANAGED_OBJECT_CONTEXT persistentStoreCoordinator] managedObjectIDForURIRepresentation:mapping.contactURI];
				if (objectId) {
					NSError *error = nil;
					Contact *contact = (Contact *)[MANAGED_OBJECT_CONTEXT existingObjectWithID:objectId error:&error];
					if (error) {
						NSLog(@"Error retreiving object: %@", [error localizedDescription]);
					}
					result = contact;
				}
			}
		}
	}];

	return result;
}

@end
