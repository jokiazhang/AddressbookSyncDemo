//
//  Address.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 09/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Address.h"

@implementation Address

@synthesize street = _street;
@synthesize city = _city;
@synthesize zip = _zip;
@synthesize state = _state;
@synthesize country = _country;


- (NSString *)description {
	return [NSString stringWithFormat:@"{%@: street: %@\n\t    city: %@\n\t    zip: %@\n\t    state: %@\n\t    country: %@}", self.label, self.street, self.city, self.zip, self.state, self.country];
}

- (void)populateWithProperties:(TFMultiValue *)properties reference:(TFMultiValueIdentifier)id {
//	self.identifier = id;
//	[self willChangeValueForKey:@"label"];
//	label = TFLocalizedPropertyOrLabel([properties labelForIdentifier:self.identifier]);
//	[self didChangeValueForKey:@"label"];
	[super populateWithProperties:properties reference:id];
	
	NSDictionary *addressDict = [properties valueForIdentifier:self.identifier];
	[self willChangeValueForKey:@"street"];
	_street = [addressDict objectForKey:kTFAddressStreetKey];
	[self didChangeValueForKey:@"street"];
	[self willChangeValueForKey:@"city"];
	_city = [addressDict objectForKey:kTFAddressCityKey];
	[self didChangeValueForKey:@"city"];
	[self willChangeValueForKey:@"state"];
	_state = [addressDict objectForKey:kTFAddressStateKey];
	[self didChangeValueForKey:@"state"];
	[self willChangeValueForKey:@"country"];
	_country = [addressDict objectForKey:kTFAddressCountryKey];
	[self didChangeValueForKey:@"country"];
	[self willChangeValueForKey:@"zip"];
	_zip = [addressDict objectForKey:kTFAddressZIPKey];
	[self didChangeValueForKey:@"zip"];
}

@end
