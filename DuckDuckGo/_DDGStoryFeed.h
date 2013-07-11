// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to DDGStoryFeed.h instead.

#import <CoreData/CoreData.h>


extern const struct DDGStoryFeedAttributes {
	__unsafe_unretained NSString *category;
	__unsafe_unretained NSString *descriptionString;
	__unsafe_unretained NSString *enabled;
	__unsafe_unretained NSString *enabledByDefault;
	__unsafe_unretained NSString *feedDate;
	__unsafe_unretained NSString *id;
	__unsafe_unretained NSString *imageDownloaded;
	__unsafe_unretained NSString *imageURLString;
	__unsafe_unretained NSString *title;
	__unsafe_unretained NSString *urlString;
} DDGStoryFeedAttributes;

extern const struct DDGStoryFeedRelationships {
	__unsafe_unretained NSString *stories;
} DDGStoryFeedRelationships;

extern const struct DDGStoryFeedFetchedProperties {
} DDGStoryFeedFetchedProperties;

@class DDGStory;












@interface DDGStoryFeedID : NSManagedObjectID {}
@end

@interface _DDGStoryFeed : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (DDGStoryFeedID*)objectID;





@property (nonatomic, strong) NSString* category;



//- (BOOL)validateCategory:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* descriptionString;



//- (BOOL)validateDescriptionString:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* enabled;



@property BOOL enabledValue;
- (BOOL)enabledValue;
- (void)setEnabledValue:(BOOL)value_;

//- (BOOL)validateEnabled:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* enabledByDefault;



@property BOOL enabledByDefaultValue;
- (BOOL)enabledByDefaultValue;
- (void)setEnabledByDefaultValue:(BOOL)value_;

//- (BOOL)validateEnabledByDefault:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* feedDate;



//- (BOOL)validateFeedDate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* id;



//- (BOOL)validateId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* imageDownloaded;



@property BOOL imageDownloadedValue;
- (BOOL)imageDownloadedValue;
- (void)setImageDownloadedValue:(BOOL)value_;

//- (BOOL)validateImageDownloaded:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* imageURLString;



//- (BOOL)validateImageURLString:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* title;



//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* urlString;



//- (BOOL)validateUrlString:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *stories;

- (NSMutableSet*)storiesSet;





@end

@interface _DDGStoryFeed (CoreDataGeneratedAccessors)

- (void)addStories:(NSSet*)value_;
- (void)removeStories:(NSSet*)value_;
- (void)addStoriesObject:(DDGStory*)value_;
- (void)removeStoriesObject:(DDGStory*)value_;

@end

@interface _DDGStoryFeed (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveCategory;
- (void)setPrimitiveCategory:(NSString*)value;




- (NSString*)primitiveDescriptionString;
- (void)setPrimitiveDescriptionString:(NSString*)value;




- (NSNumber*)primitiveEnabled;
- (void)setPrimitiveEnabled:(NSNumber*)value;

- (BOOL)primitiveEnabledValue;
- (void)setPrimitiveEnabledValue:(BOOL)value_;




- (NSNumber*)primitiveEnabledByDefault;
- (void)setPrimitiveEnabledByDefault:(NSNumber*)value;

- (BOOL)primitiveEnabledByDefaultValue;
- (void)setPrimitiveEnabledByDefaultValue:(BOOL)value_;




- (NSDate*)primitiveFeedDate;
- (void)setPrimitiveFeedDate:(NSDate*)value;




- (NSString*)primitiveId;
- (void)setPrimitiveId:(NSString*)value;




- (NSNumber*)primitiveImageDownloaded;
- (void)setPrimitiveImageDownloaded:(NSNumber*)value;

- (BOOL)primitiveImageDownloadedValue;
- (void)setPrimitiveImageDownloadedValue:(BOOL)value_;




- (NSString*)primitiveImageURLString;
- (void)setPrimitiveImageURLString:(NSString*)value;




- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;




- (NSString*)primitiveUrlString;
- (void)setPrimitiveUrlString:(NSString*)value;





- (NSMutableSet*)primitiveStories;
- (void)setPrimitiveStories:(NSMutableSet*)value;


@end
