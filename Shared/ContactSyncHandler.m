//
//  ContactSyncHandler.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 23/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ContactSyncHandler.h"
#import "Contact.h"
#import "ContactMappingCacheController.h"

@implementation ContactSyncHandler

- (id)init {
	if (self = [super init]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iCloudMergeNotification:) name:@"iCloudMergeNotification" object:[[UIApplication sharedApplication] delegate]];
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)iCloudMergeNotification:(NSNotification *)notification {
	for (Contact *contact in [[notification userInfo] valueForKey:NSInsertedObjectsKey]) {
		if ([contact isKindOfClass:[Contact class]]) {
			NSLog(@"Contact has been added as a result of a merge");
			NSMutableArray *unmatchedResults = [NSMutableArray array];
			NSMutableArray *ambigiousResults = [NSMutableArray array];
			__block NSUInteger processingCounter = 0;
			[contact syncAddressbookRecordWithCompletionHandler:^(NSArray *matches) {
				if (!matches) {
					NSLog(@"No match found for '%@'", contact.compositeName);
					[unmatchedResults addObject:contact];
				} else {
					if ([matches count] == 1) {
						contact.addressbookIdentifier = [[matches lastObject] uniqueId];
						[[ContactMappingCacheController sharedInstance] setIdentifier:contact.addressbookIdentifier forContact:contact];
					} else {
						// we have ambigious results
						NSLog(@"Ambigous results found");
						TFRecord *record;
						for (NSUInteger i = 0; i < [matches count]; i++) {
							record = [matches objectAtIndex:i];
							NSLog(@"Match on '%@ %@/%@' [%@]", [record valueForProperty:kTFFirstNameProperty], [record valueForProperty:kTFLastNameProperty], [record  valueForProperty:kTFOrganizationProperty], [record uniqueId]);
						}
						[ambigiousResults addObject:contact];
						[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChangedNotification object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
					}
				}

				processingCounter++;
				if (processingCounter == [[[notification userInfo] valueForKey:NSInsertedObjectsKey] count]) {
					NSLog(@"All iCloud import tasks complete");
					NSSet *unmatched = [[[notification userInfo] valueForKey:NSInsertedObjectsKey] filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"addressbookCacheState", kAddressbookCacheLoadFailed]];
					NSSet *ambigous = [[[notification userInfo] valueForKey:NSInsertedObjectsKey] filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"addressbookCacheState", kAddressbookCacheLoadAmbigous]];

					NSLog(@"Unmatched: %d Ambigous: %d", [unmatched count], [ambigous count]);
				}
			}];
		}
	}

	for (NSManagedObject *object in [[notification userInfo] valueForKey:NSUpdatedObjectsKey]) {
		// does our object still exist?
	}
}

@end
