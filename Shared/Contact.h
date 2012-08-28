//
//  _Contact.h
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 28/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <TFAddressBook/TFABAddressBook.h>

typedef enum {
	kAddressbookCacheNotLoaded,
	kAddressbookCacheCurrentlyLoading,
	kAddressbookCacheLoadFailed,
	kAddressbookCacheLoadAmbigous,
	kAddressbookCacheLoaded
} AddressbookCacheState;

typedef enum {
	kAddressbookSyncNotRequired,
	kAddressbookSyncInProgress
} AddressbookResyncResults;

extern NSString *kContactSyncStateChangedNotification;

@interface Contact : NSManagedObject

@property (nonatomic, strong) NSDate * lastSync;
@property (nonatomic, strong) NSString * firstName;
@property (nonatomic, strong) NSString * lastName;
@property (nonatomic, strong) NSString * company;
@property (nonatomic) BOOL isCompany;
@property (nonatomic, strong) NSString * sortTag1;
@property (nonatomic, strong) NSString * sortTag2;

@property (nonatomic, readonly) NSArray *ambigousContactMatches;

@property (strong, nonatomic, readonly) NSString *compositeName;
@property (strong, nonatomic, readonly) NSString *secondaryCompositeName;
@property (strong, nonatomic, readonly) NSString *helpfullText;

@property (strong, nonatomic, readonly) NSString *groupingIndexCharacter;

@property (assign) AddressbookCacheState addressbookCacheState;
@property (strong) TFRecordID addressbookIdentifier;
@property (assign) BOOL addressbookIdentifierChanged;

@property (strong, nonatomic, readonly) NSArray *phoneNumbers;
@property (strong, nonatomic, readonly) NSArray *emailAddresses;
@property (strong, nonatomic, readonly) NSArray *addresses;
@property (strong, nonatomic, readonly) NSArray *websites;

+ (Contact *)initContactWithAddressbookRecord:(TFRecord *)record;
+ (Contact *)findContactForRecordId:(TFRecordID)recordId;
+ (NSOperationQueue *)sharedOperationQueue;

- (AddressbookResyncResults)syncAddressbookRecordWithCompletionHandler:(void(^)(NSArray *matches))completionHandler;
- (void)updateManagedObjectWithAddressbookRecordDetails;
- (BOOL)isContactOlderThanAddressbookRecord:(TFRecord *)record;
- (void)resolveConflictWithAddressbookRecordId:(TFRecordID)recordId;
- (TFRecord *)addressbookRecordInAddressBook:(TFAddressBook *)addressBook;
- (void)addressbookRecordInAddressBook:(TFAddressBook *)addressBook completionHandler:(void(^)(TFRecord *record))completionHandler;

@end
