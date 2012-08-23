//
//  ContactMappingCacheController.h
//  AddressBookSyncDemo_OSX
//
//  Created by Tom Fewster on 23/08/2012.
//  Copyright (c) 2012 Tom Fewster. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TFAddressBook/TFABAddressBook.h>

@class Contact;

@interface ContactMappingCacheController : NSObject

+ (ContactMappingCacheController *)sharedInstance;
- (TFRecordID)identifierForContact:(Contact *)contact;
- (void)setIdentifier:(TFRecordID)identifier forContact:(Contact *)contact;
- (void)removeIdentifierForContact:(Contact *)contact;
- (BOOL)contactExistsForIdentifier:(TFRecordID)identifier;
- (Contact *)contactObjectForIdentifier:(TFRecordID)identifier;

@end
