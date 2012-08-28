//
//  AppDelegate.h
//  AddressbookSyncDemoMac
//
//  Created by Tom Fewster on 27/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AddressBook/ABPersonView.h>
#import <TFAddressBook/TFABAddressBook.h>

@class AmbigousContactResolverViewController;
@class UnresolvedContactResolverViewController;
@class Contact;
@class CoreDataController;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (nonatomic, strong, readonly) CoreDataController *coreDataController;
@property (nonatomic, retain) NSIndexSet *contactSelectionIndex;
@property (weak) IBOutlet ABPersonView *personView;
@property (weak) IBOutlet NSArrayController *arrayController;
@property (strong) IBOutlet AmbigousContactResolverViewController *ambigousContactResolver;
@property (strong) IBOutlet UnresolvedContactResolverViewController *unresolvedContactResolver;

@property (weak, readonly, nonatomic) NSArray *sortDescriptors;
@property (strong) NSPredicate *searchFilter;
@property (strong) Contact *selectedContact;

- (IBAction)saveAction:(id)sender;

@end
