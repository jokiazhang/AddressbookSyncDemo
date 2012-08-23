//
//  Address.h
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 09/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "_ContactMultiProperty.h"

@interface Address : _ContactMultiProperty

@property (readonly, strong, nonatomic) NSString *street;
@property (readonly, strong, nonatomic) NSString *city;
@property (readonly, strong, nonatomic) NSString *zip;
@property (readonly, strong, nonatomic) NSString *state;
@property (readonly, strong, nonatomic) NSString *country;

@end
