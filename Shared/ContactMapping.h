//
//  ContactMapping.h
//  AddressBookSyncDemo_OSX
//
//  Created by Tom Fewster on 23/08/2012.
//  Copyright (c) 2012 Tom Fewster. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ContactMapping : NSManagedObject

@property (nonatomic, retain) NSString * addressbookReference;
@property (nonatomic, retain) id contactURI;

@end
