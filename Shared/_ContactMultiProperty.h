//
//  _PhoneNumber.h
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 29/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TFAddressBook/TFABAddressBook.h>

@interface _ContactMultiProperty : NSObject

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
@property (assign) TFMultiValueIdentifier identifier;
#else
@property (strong) TFMultiValueIdentifier identifier;
#endif
@property (readonly, strong, nonatomic) NSString *label;
@property (readonly, strong, nonatomic) NSString *value;

- (void)populateWithProperties:(TFMultiValue *)properties reference:(TFMultiValueIdentifier)identifier;

@end
