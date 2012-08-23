//
//  Global.h
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 27/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NSManagedObjectContext+SearchExtensions.h"
#import "NSObject+BlockExtensions.h"
#import "CoreDataController.h"
#import "AppDelegate.h"

#ifdef UNIT_TEST
extern NSManagedObjectContext *s_unitTestManagedObjectContext;
#	define MANAGED_OBJECT_CONTEXT s_unitTestManagedObjectContext
#else
#	if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
@protocol UIManagedObjectApplicationDelegate <UIApplicationDelegate>
@property (readonly) CoreDataController *coreDataController;
@end
#		define UIApp [UIApplication sharedApplication]
//#		define MANAGED_OBJECT_CONTEXT [((NSObject<UIManagedObjectApplicationDelegate> *)[UIApp delegate]) managedObjectContext]
#		define MANAGED_OBJECT_CONTEXT ((AppDelegate *)[UIApp delegate]).coreDataController.mainThreadContext
#	else
//#		define MANAGED_OBJECT_CONTEXT [[NSApp delegate] managedObjectContext]
#		define MANAGED_OBJECT_CONTEXT ((AppDelegate *)[NSApp delegate]).coreDataController.mainThreadContext
#	endif
#endif
