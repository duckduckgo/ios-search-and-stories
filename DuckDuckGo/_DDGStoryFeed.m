// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to DDGStoryFeed.m instead.

#import "_DDGStoryFeed.h"

const struct DDGStoryFeedAttributes DDGStoryFeedAttributes = {
	.category = @"category",
	.descriptionString = @"descriptionString",
	.enabled = @"enabled",
	.enabledByDefault = @"enabledByDefault",
	.feedDate = @"feedDate",
	.id = @"id",
	.imageDownloaded = @"imageDownloaded",
	.imageURLString = @"imageURLString",
	.title = @"title",
	.urlString = @"urlString",
};

const struct DDGStoryFeedRelationships DDGStoryFeedRelationships = {
	.stories = @"stories",
};

@implementation DDGStoryFeedID
@end

@implementation _DDGStoryFeed

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Feed" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Feed";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Feed" inManagedObjectContext:moc_];
}

- (DDGStoryFeedID*)objectID {
	return (DDGStoryFeedID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"enabledValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"enabled"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"enabledByDefaultValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"enabledByDefault"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"imageDownloadedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"imageDownloaded"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic category;

@dynamic descriptionString;

@dynamic enabled;

- (int16_t)enabledValue {
	NSNumber *result = [self enabled];
	return [result shortValue];
}

- (void)setEnabledValue:(int16_t)value_ {
	[self setEnabled:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveEnabledValue {
	NSNumber *result = [self primitiveEnabled];
	return [result shortValue];
}

- (void)setPrimitiveEnabledValue:(int16_t)value_ {
	[self setPrimitiveEnabled:[NSNumber numberWithShort:value_]];
}

@dynamic enabledByDefault;

- (BOOL)enabledByDefaultValue {
	NSNumber *result = [self enabledByDefault];
	return [result boolValue];
}

- (void)setEnabledByDefaultValue:(BOOL)value_ {
	[self setEnabledByDefault:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveEnabledByDefaultValue {
	NSNumber *result = [self primitiveEnabledByDefault];
	return [result boolValue];
}

- (void)setPrimitiveEnabledByDefaultValue:(BOOL)value_ {
	[self setPrimitiveEnabledByDefault:[NSNumber numberWithBool:value_]];
}

@dynamic feedDate;

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

@dynamic title;

@dynamic urlString;

@dynamic stories;

- (NSMutableSet*)storiesSet {
	[self willAccessValueForKey:@"stories"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"stories"];

	[self didAccessValueForKey:@"stories"];
	return result;
}

@end

