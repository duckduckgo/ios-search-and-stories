// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to DDGHistoryItem.m instead.

#import "_DDGHistoryItem.h"

const struct DDGHistoryItemAttributes DDGHistoryItemAttributes = {
	.section = @"section",
	.timeStamp = @"timeStamp",
	.title = @"title",
	.urlString = @"urlString",
};

const struct DDGHistoryItemRelationships DDGHistoryItemRelationships = {
	.story = @"story",
};

const struct DDGHistoryItemFetchedProperties DDGHistoryItemFetchedProperties = {
};

@implementation DDGHistoryItemID
@end

@implementation _DDGHistoryItem

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"HistoryItem" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"HistoryItem";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"HistoryItem" inManagedObjectContext:moc_];
}

- (DDGHistoryItemID*)objectID {
	return (DDGHistoryItemID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic section;






@dynamic timeStamp;






@dynamic title;






@dynamic urlString;






@dynamic story;

	






@end
