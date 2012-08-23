//
//  URLValueTransformer.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 22/08/2012.
//
//

#import "URLValueTransformer.h"

@implementation URLValueTransformer

+ (Class)transformedValueClass {
	return [NSData class];
}

+ (BOOL)allowsReverseTransformation {
	return YES;
}

- (id)transformedValue:(NSURL *)url {
	if (url == nil)
		return nil;

	NSString *key = [url absoluteString];
	return [key dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSURL *)reverseTransformedValue:(NSData *)data {

	return [NSURL URLWithString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
}

@end
