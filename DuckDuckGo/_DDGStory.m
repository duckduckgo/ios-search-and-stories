// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to DDGStory.m instead.

#import "_DDGStory.h"

const struct DDGStoryAttributes DDGStoryAttributes = {
	.articleURLString = @"articleURLString",
	.category = @"category",
	.descriptionString = @"descriptionString",
	.feedDate = @"feedDate",
	.htmlDownloaded = @"htmlDownloaded",
	.id = @"id",
	.imageDownloaded = @"imageDownloaded",
	.imageURLString = @"imageURLString",
	.read = @"read",
	.saved = @"saved",
	.timeStamp = @"timeStamp",
	.title = @"title",
	.urlString = @"urlString",
};

const struct DDGStoryRelationships DDGStoryRelationships = {
	.feed = @"feed",
	.recents = @"recents",
};

@implementation DDGStoryID
@end

@implementation _DDGStory

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Story" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Story";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Story" inManagedObjectContext:moc_];
}

- (DDGStoryID*)objectID {
	return (DDGStoryID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"htmlDownloadedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"htmlDownloaded"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"imageDownloadedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"imageDownloaded"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"readValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"read"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"savedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"saved"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic articleURLString;

@dynamic category;

@dynamic descriptionString;

@dynamic feedDate;

@dynamic htmlDownloaded;

- (BOOL)htmlDownloadedValue {
	NSNumber *result = [self htmlDownloaded];
	return [result boolValue];
}

- (void)setHtmlDownloadedValue:(BOOL)value_ {
	[self setHtmlDownloaded:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveHtmlDownloadedValue {
	NSNumber *result = [self primitiveHtmlDownloaded];
	return [result boolValue];
}

- (void)setPrimitiveHtmlDownloadedValue:(BOOL)value_ {
	[self setPrimitiveHtmlDownloaded:[NSNumber numberWithBool:value_]];
}

@dynamic id;

@dynamic imageDownloaded;

- (BOOL)imageDownloadedValue {
	NSNumber *result = [self imageDownloaded];
	return [result boolValue];
}

- (void)setImageDownloadedValue:(BOOL)value_ {
	[self setImageDownloaded:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveImageDownloadedValue {
	NSNumber *result = [self primitiveImageDownloaded];
	return [result boolValue];
}

- (void)setPrimitiveImageDownloadedValue:(BOOL)value_ {
	[self setPrimitiveImageDownloaded:[NSNumber numberWithBool:value_]];
}

@dynamic imageURLString;

@dynamic read;

- (BOOL)readValue {
	NSNumber *result = [self read];
	return [result boolValue];
}

- (void)setReadValue:(BOOL)value_ {
	[self setRead:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveReadValue {
	NSNumber *result = [self primitiveRead];
	return [result boolValue];
}

- (void)setPrimitiveReadValue:(BOOL)value_ {
	[self setPrimitiveRead:[NSNumber numberWithBool:value_]];
}

@dynamic saved;

- (BOOL)savedValue {
	NSNumber *result = [self saved];
	return [result boolValue];
}

- (void)setSavedValue:(BOOL)value_ {
	[self setSaved:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveSavedValue {
	NSNumber *result = [self primitiveSaved];
	return [result boolValue];
}

- (void)setPrimitiveSavedValue:(BOOL)value_ {
	[self setPrimitiveSaved:[NSNumber numberWithBool:value_]];
}

@dynamic timeStamp;

@dynamic title;

@dynamic urlString;

@dynamic feed;

@dynamic recents;

- (NSMutableSet*)recentsSet {
	[self willAccessValueForKey:@"recents"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"recents"];

	[self didAccessValueForKey:@"recents"];
	return result;
}

@end

