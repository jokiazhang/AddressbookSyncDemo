//
//  Contact.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 28/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
//#define MULTI_THREADED 1

#import "AppDelegate.h"
#import "Contact.h"
#import "PhoneNumber.h"
#import "EmailAddress.h"
#import "Website.h"
#import "Address.h"
#import "ContactMappingCacheController.h"

//#define MULTI_THREADED 1

NSString *kContactSyncStateChangedNotification = @"kContactSyncStateChanged";

@interface Contact ()
@property (strong) NSArray *ambigousPossibleMatches;
@end

@implementation Contact

@dynamic lastSync;
@dynamic firstName;
@dynamic lastName;
@dynamic company;
@dynamic isCompany;
@dynamic sortTag1;
@dynamic sortTag2;

// These must be declared in the subclass
@dynamic compositeName;
@dynamic secondaryCompositeName;

@synthesize addressbookIdentifier = _addressbookIdentifier;
@synthesize addressbookCacheState = _addressbookCacheState;
@synthesize ambigousContactMatches = _ambigousContactMatches;
@synthesize ambigousPossibleMatches = _ambigousPossibleMatches;
@synthesize addresses = _addresses;
@synthesize emailAddresses = _emailAddresses;
@synthesize websites = _websites;
@synthesize phoneNumbers = _phoneNumbers;

+ (NSOperationQueue *)sharedOperationQueue {
	static dispatch_once_t onceToken = 0;
	__strong static NSOperationQueue *_operationQueue = nil;
	dispatch_once(&onceToken, ^{
		_operationQueue = [[NSOperationQueue alloc] init];
	});
	return _operationQueue;
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	if ([key isEqualToString:@"compositeName"]) {
		return [NSSet setWithObjects:@"firstName", @"lastName", @"company", @"addressbookIdentifier", nil];
	} else if ([key isEqualToString:@"secondaryCompositeName"]) {
		return [NSSet setWithObjects:@"firstName", @"lastName", @"company", @"addressbookIdentifier", nil];
	} else if ([key isEqualToString:@"helpfullText"]) {
		return [NSSet setWithObjects:@"addressbookIdentifier", @"addressbookCacheState", @"_addressbookCacheState", @"sortTag1", @"sortTag2", nil];
	}
	
	return nil;
}

+ (Contact *)findContactForRecordId:(TFRecordID)recordId {
	return (Contact *)[[ContactMappingCacheController sharedInstance] contactObjectForIdentifier:recordId];
}

+ (Contact *)initContactWithAddressbookRecord:(TFRecord *)record {
	// Add this contact to the Object Graph
	Contact *contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:MANAGED_OBJECT_CONTEXT];
	contact.addressbookIdentifier = [record uniqueId];
	[contact updateManagedObjectWithAddressbookRecordDetails];
	
	return contact;
}

- (void)awakeFromFetch {
	[super awakeFromFetch];
	NSLog(@"Contact '%@' has been initialiased, loading details from cache", self.compositeName);
	_addressbookCacheState = kAddressbookCacheNotLoaded;

	void(^matchCompleted)(NSArray *matches) = ^(NSArray *matches) {
		if (!matches) {
			NSLog(@"No match found for '%@'", self.compositeName);
		} else {
			if ([matches count] == 1) {
				self.addressbookIdentifier = [[matches lastObject] uniqueId];
				[[ContactMappingCacheController sharedInstance] setIdentifier:self.addressbookIdentifier forContact:self];
				[self updateManagedObjectWithAddressbookRecordDetails];
			} else {
				// we have ambigious results
				NSLog(@"Ambigous results found");
				TFRecord *record;
				for (NSUInteger i = 0; i < [matches count]; i++) {
					record = [matches objectAtIndex:i];
					NSLog(@"Match on '%@ %@/%@' [%@]", [record valueForProperty:kTFFirstNameProperty], [record valueForProperty:kTFLastNameProperty], [record  valueForProperty:kTFOrganizationProperty], [record uniqueId]);
				}
				_ambigousPossibleMatches = [matches valueForKeyPath:@"uniqueId"];
				[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChangedNotification object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
			}
		}
	};
	
	if (self.addressbookIdentifier != 0) {
		TFRecord *record = [self addressbookRecordInAddressBook:[TFAddressBook addressBook]];
		if (record == nil) { // i.e. we couldn't find the record
			NSLog(@"The value we had for addressbook identifier was incorrect ('%@' didn't exist)", self.compositeName);
			self.addressbookIdentifier = 0;
			[[ContactMappingCacheController sharedInstance] removeIdentifierForContact:self];
			[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChangedNotification object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
			[self syncAddressbookRecordWithCompletionHandler:matchCompleted];
		} else {
			if ([self isContactOlderThanAddressbookRecord:record]) {
				NSLog(@"Addressbook contact is newer, we need to update our cache");
				[self updateManagedObjectWithAddressbookRecordDetails];
			}
			_addressbookCacheState = kAddressbookCacheLoaded;
			NSLog(@"Contact '%@' loaded", self.compositeName);
		}
	} else {
		NSLog(@"Contact '%@' has no identifier in the mapping yet", self.compositeName);

		[self syncAddressbookRecordWithCompletionHandler:matchCompleted];
	}
}

- (void)awakeFromInsert {
	[super awakeFromInsert];
	_addressbookCacheState = kAddressbookCacheNotLoaded;
}

- (void)didSave {
	if ([self isDeleted]) {
		NSLog(@"Removing identifier from Contacts Mapping");
		[[ContactMappingCacheController sharedInstance] removeIdentifierForContact:self];
	} else if (self.addressbookIdentifier) {
		NSLog(@"Adding/Updating identifier in Contacts Mapping");
		[[ContactMappingCacheController sharedInstance] setIdentifier:self.addressbookIdentifier forContact:self];
	}	
}

- (BOOL)isContactOlderThanAddressbookRecord:(TFRecord *)record {
	if (self.lastSync == nil) {
		return true;
	}
	NSDate *modificationDate = [record valueForProperty:kTFModificationDateProperty];
	return ([self.lastSync laterDate:modificationDate] == modificationDate);
}

- (TFRecordID)addressbookIdentifier {
	if (_addressbookIdentifier == 0) {
		_addressbookIdentifier = [[ContactMappingCacheController sharedInstance] identifierForContact:self];
	}
	return _addressbookIdentifier;
}


- (TFRecord *)addressbookRecordInAddressBook:(TFAddressBook *)addressBook {
	if (self.addressbookIdentifier != 0) {
		return [addressBook recordForUniqueId:self.addressbookIdentifier];
	}
	return nil;
}

- (void)updateManagedObjectWithAddressbookRecordDetails {

	TFPerson *record = (TFPerson *)[self addressbookRecordInAddressBook:[TFAddressBook addressBook]];
	
	if (record == nil) {
		NSLog(@"Can't update record, object's _addressbookRecord is nil");
		NSLog(@"The value we had for addressbook identifier was incorrect ('%@' didn't exist)", self.compositeName);
		self.addressbookIdentifier = 0;
		[[ContactMappingCacheController sharedInstance] removeIdentifierForContact:self];
		_addressbookCacheState = kAddressbookCacheNotLoaded;

		[self syncAddressbookRecordWithCompletionHandler:^(NSArray *matches) {
			if (!matches) {
				NSLog(@"No match found for '%@'", self.compositeName);
			} else {
				if ([matches count] == 1) {
					self.addressbookIdentifier = [[matches lastObject] uniqueId];
					[[ContactMappingCacheController sharedInstance] setIdentifier:self.addressbookIdentifier forContact:self];
					[self updateManagedObjectWithAddressbookRecordDetails];
				} else {
					// we have ambigious results
					NSLog(@"Ambigous results found");
					TFRecord *record;
					for (NSUInteger i = 0; i < [matches count]; i++) {
						record = [matches objectAtIndex:i];
						NSLog(@"Match on '%@ %@/%@' [%@]", [record valueForProperty:kTFFirstNameProperty], [record valueForProperty:kTFLastNameProperty], [record  valueForProperty:kTFOrganizationProperty], [record uniqueId]);
					}
					_ambigousPossibleMatches = [matches valueForKeyPath:@"uniqueId"];
					[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChangedNotification object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
				}
			}
		}];

	} else {
		NSInteger personFlags = [[record valueForProperty:kTFPersonFlags] integerValue];
		self.isCompany = (personFlags & kTFShowAsCompany);
		
		self.firstName = [record valueForProperty:kTFFirstNameProperty];
		self.lastName = [record valueForProperty:kTFLastNameProperty];
		self.company = [record valueForProperty:kTFOrganizationProperty];
		
		NSDate *modificationDate = [record valueForProperty:kTFModificationDateProperty];
		if (modificationDate) {
			self.lastSync = modificationDate;
		} else {
			NSLog(@"Contact has no last modification date");
		}
		
		[self willChangeValueForKey:@"_addresses"];
		[self willChangeValueForKey:@"_phoneNumbers"];
		[self willChangeValueForKey:@"_emailAddresses"];
		[self willChangeValueForKey:@"_websites"];
		_addresses = nil;
		_phoneNumbers = nil;
		_emailAddresses = nil;
		_websites = nil;
		[self didChangeValueForKey:@"_addresses"];
		[self didChangeValueForKey:@"_phoneNumbers"];
		[self didChangeValueForKey:@"_emailAddresses"];
		[self didChangeValueForKey:@"_websites"];
	}
	
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kContactSyncStateChangedNotification object:self  userInfo:[NSDictionary dictionaryWithObject:self forKey:NSUpdatedObjectsKey]]];
}

- (NSArray *)ambigousContactMatches {
	return _ambigousPossibleMatches;	
}

- (void)resolveConflictWithAddressbookRecordId:(TFRecordID)recordId {
	self.addressbookIdentifier = recordId;
	[self updateManagedObjectWithAddressbookRecordDetails];
	NSLog(@"Conflict for '%@' is now resolved", self.compositeName);
}

- (AddressbookResyncResults)syncAddressbookRecordWithCompletionHandler:(void(^)(NSArray *matches))completionHandler {
	if (!self.addressbookIdentifier && _addressbookCacheState == kAddressbookCacheNotLoaded) {
		_addressbookCacheState = kAddressbookCacheCurrentlyLoading;

		NSLog(@"We need to look up the contact & attempt to sync with Addressbook");

#ifdef MULTI_THREADED
#endif
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{

			TFSearchElement *firstNameSearchElement = [TFPerson searchElementForProperty:kTFFirstNameProperty label:nil key:nil value:self.firstName comparison:kTFEqualCaseInsensitive];
			TFSearchElement *lastNameSearchElement = [TFPerson searchElementForProperty:kTFLastNameProperty label:nil key:nil value:self.lastName comparison:kTFEqualCaseInsensitive];
			TFSearchElement *companySearchElement = [TFPerson searchElementForProperty:kTFOrganizationProperty label:nil key:nil value:self.company comparison:kTFEqualCaseInsensitive];
			
			TFSearchElement *compositeSearchElement = [TFSearchElement searchElementForConjunction:kTFSearchAnd children:[NSArray arrayWithObjects:firstNameSearchElement, lastNameSearchElement, companySearchElement, nil]];
			
			TFAddressBook *addressbook = [TFAddressBook addressBook];
			NSLog(@"%@", compositeSearchElement);
			NSArray *people = [addressbook recordsMatchingSearchElement:compositeSearchElement];
			
			// Filter out everyone who matches these properties & doesn't currently have a mapping to a existing Contact
			NSArray *filteredPeople = [people filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
				NSInteger personFlags = [[(TFPerson *)evaluatedObject valueForProperty:kTFPersonFlags] integerValue];
				return (self.isCompany == (personFlags & kTFShowAsCompany));
			}]];
			
			NSUInteger count = [filteredPeople count];

			if (count == 0) {
				dispatch_sync(dispatch_get_main_queue(), ^{
					_addressbookCacheState = kAddressbookCacheLoadFailed;
					completionHandler(nil);
				});
			} else if (count == 1) {
				dispatch_sync(dispatch_get_main_queue(), ^{
					completionHandler(filteredPeople);
				});
			} else {
				dispatch_sync(dispatch_get_main_queue(), ^{
					_addressbookCacheState = kAddressbookCacheLoadAmbigous;
					completionHandler(filteredPeople);
				});
			}
		});
		return kAddressbookSyncInProgress;
	} else {
		return kAddressbookSyncNotRequired;
	}
}

- (NSString *)compositeName {
	if (self.isCompany) {
		return self.company;
	} else {
		NSString *firstName = (self.firstName?self.firstName:@"");
		NSString *lastName = (self.lastName?self.lastName:@"");
		if ([[TFAddressBook addressBook] defaultNameOrdering] == kTFFirstNameFirst) {
			return [NSString stringWithFormat:@"%@ %@", firstName, lastName];
		} else {
			return [NSString stringWithFormat:@"%@ %@", lastName, firstName];
		}
	}
}

- (NSString *)helpfullText {
	return self.addressbookIdentifier?[NSString stringWithFormat:@"%@ ['%@', '%@'] - '%@'", self.addressbookIdentifier, self.sortTag1, self.sortTag2, self.groupingIndexCharacter]:@"Contact not found";
}


- (NSString *)secondaryCompositeName {
	if (!self.isCompany) {
		return self.company;
	} else {
		NSString *firstName = (self.firstName?self.firstName:@"");
		NSString *lastName = (self.lastName?self.lastName:@"");
		if ([[TFAddressBook addressBook] defaultNameOrdering] == kTFFirstNameFirst) {
			return [NSString stringWithFormat:@"%@ %@", firstName, lastName];
		} else {
			return [NSString stringWithFormat:@"%@ %@", lastName, firstName];
		}
	}
}

- (NSString *)groupingIndexCharacter {
	NSString *result = nil;
	if (self.isCompany) {
		if (self.company) {
			result = self.company;
		} else if (self.lastName) {
			result = self.lastName;
		} else if (self.firstName) {
			result = self.firstName;
		} else {
			result = @"N";
		}
	} else {
		if (self.lastName) {
			result = self.lastName;
		} else if (self.firstName) {
			result = self.firstName;
		} else if (self.company) {
			result = self.company;
		} else {
			result = @"N";
		}
	}
	
	return [[result substringWithRange:NSMakeRange([result rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location, 1)] uppercaseString];
}

- (void)resetSearchTags {
	NSRange range = [self.company rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];
	NSString *c = [[self.company substringWithRange:NSMakeRange(range.location, [self.company length]-range.location)] uppercaseString];
	range = [self.firstName rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];
	NSString *f = [[self.firstName substringWithRange:NSMakeRange(range.location, [self.firstName length]-range.location)] uppercaseString];
	range = [self.lastName rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];
	NSString *l = [[self.lastName substringWithRange:NSMakeRange(range.location, [self.lastName length]-range.location)] uppercaseString];
	if (self.isCompany) {
		if (c) {
			self.sortTag1 = c;
			self.sortTag2 = c;
		} else if (f) {
			self.sortTag1 = f;
			if (l) {
				self.sortTag2 = l;
			} else {
				self.sortTag2 = f;
			}
		} else if (l) {
			self.sortTag1 = l;
			self.sortTag2 = l;
		}
	} else {
		if (f) {
			self.sortTag1 = f;
			if (l) {
				self.sortTag2 = l;
			} else {
				self.sortTag2 = f;
			}
		} else if (l) {
			self.sortTag1 = l;
			self.sortTag2 = l;
		} else if (c) {
			self.sortTag1 = c;
			self.sortTag2 = c;
		}
	}
}

- (void)setFirstName:(NSString *)firstName {
	[self willChangeValueForKey:@"firstName"];
	[self setPrimitiveValue:firstName forKey:@"firstName"];
	[self didChangeValueForKey:@"firstName"];
	[self resetSearchTags];
}

- (void)setLastName:(NSString *)lastName {
	[self willChangeValueForKey:@"lastName"];
	[self setPrimitiveValue:lastName forKey:@"lastName"];
	[self didChangeValueForKey:@"lastName"];
	[self resetSearchTags];
}

- (void)setCompany:(NSString *)company {
	[self willChangeValueForKey:@"company"];
	[self setPrimitiveValue:company forKey:@"company"];
	[self didChangeValueForKey:@"company"];	
	[self resetSearchTags];
}

- (NSArray *)phoneNumbers {
	if (_phoneNumbers == nil) {
		TFRecord *record = [self addressbookRecordInAddressBook:[TFAddressBook addressBook]];
		if (record) {
			TFMultiValue *properties = [record valueForProperty:kTFPhoneProperty];
			NSMutableArray *values = [NSMutableArray array];
			for (NSUInteger i = 0; i < [properties count]; i++) {
				TFMultiValueIdentifier identifier = [properties identifierAtIndex:i];
				NSUInteger index = NSNotFound;
				if (_phoneNumbers) {
					index = [_phoneNumbers indexOfObjectPassingTest:^BOOL(PhoneNumber *obj, NSUInteger idx, BOOL *stop) {
						return obj.identifier == identifier;
					}];
				}
				
				PhoneNumber *phoneNumber;
				if (index == NSNotFound) {
					NSLog(@"creating new");
					phoneNumber = [[PhoneNumber alloc] init];
				} else {
					NSLog(@"reusing & updating");
					phoneNumber = [_phoneNumbers objectAtIndex:index];
				}
				[values addObject:phoneNumber];
				[phoneNumber populateWithProperties:properties reference:identifier];
			}
			_phoneNumbers = values;
		}
	}
	return _phoneNumbers;
}

- (NSArray *)emailAddresses {
	if (_emailAddresses == nil) {
		TFRecord *record = [self addressbookRecordInAddressBook:[TFAddressBook addressBook]];
		if (record) {
			TFMultiValue *properties = [record valueForProperty:kTFEmailProperty];
			NSMutableArray *values = [NSMutableArray array];
			for (NSUInteger i = 0; i < [properties count]; i++) {
				TFMultiValueIdentifier identifier = [properties identifierAtIndex:i];
				NSUInteger index = NSNotFound;
				if (_emailAddresses) {
					index = [_emailAddresses indexOfObjectPassingTest:^BOOL(PhoneNumber *obj, NSUInteger idx, BOOL *stop) {
						return obj.identifier == identifier;
					}];
				}
				
				EmailAddress *emailAddress;
				if (index == NSNotFound) {
					NSLog(@"creating new");
					emailAddress = [[EmailAddress alloc] init];
				} else {
					NSLog(@"reusing & updating");
					emailAddress = [_emailAddresses objectAtIndex:index];
				}
				[values addObject:emailAddress];
				[emailAddress populateWithProperties:properties reference:identifier];
			}
			_emailAddresses = values;
		}
	}
	return _emailAddresses;
}

- (NSArray *)addresses {
	if (_addresses == nil) {
		TFRecord *record = [self addressbookRecordInAddressBook:[TFAddressBook addressBook]];
		if (record) {
			TFMultiValue *properties = [record valueForProperty:kTFAddressProperty];
			NSMutableArray *values = [NSMutableArray array];
			for (NSUInteger i = 0; i < [properties count]; i++) {
				TFMultiValueIdentifier identifier = [properties identifierAtIndex:i];
				NSUInteger index = NSNotFound;
				if (_addresses) {
					index = [_addresses indexOfObjectPassingTest:^BOOL(Address *obj, NSUInteger idx, BOOL *stop) {
						return obj.identifier == identifier;
					}];
				}
				
				Address *address;
				if (index == NSNotFound) {
					NSLog(@"creating new");
					address = [[Address alloc] init];
				} else {
					NSLog(@"reusing & updating");
					address = [_addresses objectAtIndex:index];
				}
				[values addObject:address];
				[address populateWithProperties:properties reference:identifier];
			}
			_addresses = values;
		}
	}
	return _addresses;
}

- (NSArray *)websites {
	if (_websites == nil) {	
		TFRecord *record = [self addressbookRecordInAddressBook:[TFAddressBook addressBook]];
		if (record) {
			TFMultiValue *properties = [record valueForProperty:kTFURLsProperty];
			NSMutableArray *values = [NSMutableArray array];
			for (NSUInteger i = 0; i < [properties count]; i++) {
				TFMultiValueIdentifier identifier = [properties identifierAtIndex:i];
				NSUInteger index = NSNotFound;
				if (_websites) {
					index = [_websites indexOfObjectPassingTest:^BOOL(Website *obj, NSUInteger idx, BOOL *stop) {
						return obj.identifier == identifier;
					}];
				}				
				Website *website;
				if (index == NSNotFound) {
					NSLog(@"creating new");
					website = [[Website alloc] init];
				} else {
					NSLog(@"reusing & updating");
					website = [_websites objectAtIndex:index];
				}
				[values addObject:website];
				[website populateWithProperties:properties reference:identifier];
			}
			_websites = values;
		}
	}
	return _websites;
}

@end
