//
//  _PhoneNumber.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 29/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "_ContactMultiProperty.h"
#import <TFAddressBook/TFABAddressBook.h>

@implementation _ContactMultiProperty

@synthesize identifier = _identifier;
@synthesize value = _value;
@synthesize label = _label;

- (NSString *)description {
	return [NSString stringWithFormat:@"{%@: %@ [%@]}", _label, _value, _identifier];
}

- (void)populateWithProperties:(TFMultiValue *)properties reference:(TFMultiValueIdentifier)reference {
	_identifier = reference;
	[self willChangeValueForKey:@"label"];
	_label = TFLocalizedPropertyOrLabel([properties labelForIdentifier:_identifier]);
	[self didChangeValueForKey:@"label"];
	[self willChangeValueForKey:@"value"];
	_value = [properties valueForIdentifier:_identifier];
	[self didChangeValueForKey:@"value"];
}

- (BOOL)isEqual:(_ContactMultiProperty *)object {
	return CompareTFMultiValueIdentifiers(_identifier, object.identifier);
}

- (NSUInteger)hash {
	return (NSUInteger)_identifier;
}

@end
