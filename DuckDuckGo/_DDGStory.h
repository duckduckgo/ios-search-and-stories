// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to DDGStory.h instead.

#import <CoreData/CoreData.h>


extern const struct DDGStoryAttributes {
	__unsafe_unretained NSString *articleURLString;
	__unsafe_unretained NSString *descriptionString;
	__unsafe_unretained NSString *feedDate;
	__unsafe_unretained NSString *htmlDownloaded;
	__unsafe_unretained NSString *id;
	__unsafe_unretained NSString *imageDownloaded;
	__unsafe_unretained NSString *imageURLString;
	__unsafe_unretained NSString *read;
	__unsafe_unretained NSString *saved;
	__unsafe_unretained NSString *timeStamp;
	__unsafe_unretained NSString *title;
	__unsafe_unretained NSString *urlString;
} DDGStoryAttributes;

extern const struct DDGStoryRelationships {
	__unsafe_unretained NSString *feed;
} DDGStoryRelationships;

extern const struct DDGStoryFetchedProperties {
} DDGStoryFetchedProperties;

@class DDGStoryFeed;














@interface DDGStoryID : NSManagedObjectID {}
@end

@interface _DDGStory : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (DDGStoryID*)objectID;




@property (nonatomic, strong) NSString* articleURLString;


//- (BOOL)validateArticleURLString:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* descriptionString;


//- (BOOL)validateDescriptionString:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSDate* feedDate;


//- (BOOL)validateFeedDate:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* htmlDownloaded;


@property BOOL htmlDownloadedValue;
- (BOOL)htmlDownloadedValue;
- (void)setHtmlDownloadedValue:(BOOL)value_;

//- (BOOL)validateHtmlDownloaded:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* id;


//- (BOOL)validateId:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* imageDownloaded;


@property BOOL imageDownloadedValue;
- (BOOL)imageDownloadedValue;
- (void)setImageDownloadedValue:(BOOL)value_;

//- (BOOL)validateImageDownloaded:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* imageURLString;


//- (BOOL)validateImageURLString:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* read;


@property BOOL readValue;
- (BOOL)readValue;
- (void)setReadValue:(BOOL)value_;

//- (BOOL)validateRead:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* saved;


@property BOOL savedValue;
- (BOOL)savedValue;
- (void)setSavedValue:(BOOL)value_;

//- (BOOL)validateSaved:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSDate* timeStamp;


//- (BOOL)validateTimeStamp:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* title;


//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* urlString;


//- (BOOL)validateUrlString:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) DDGStoryFeed* feed;

//- (BOOL)validateFeed:(id*)value_ error:(NSError**)error_;





@end

@interface _DDGStory (CoreDataGeneratedAccessors)

@end

@interface _DDGStory (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveArticleURLString;
- (void)setPrimitiveArticleURLString:(NSString*)value;




- (NSString*)primitiveDescriptionString;
- (void)setPrimitiveDescriptionString:(NSString*)value;




- (NSDate*)primitiveFeedDate;
- (void)setPrimitiveFeedDate:(NSDate*)value;




- (NSNumber*)primitiveHtmlDownloaded;
- (void)setPrimitiveHtmlDownloaded:(NSNumber*)value;

- (BOOL)primitiveHtmlDownloadedValue;
- (void)setPrimitiveHtmlDownloadedValue:(BOOL)value_;




- (NSString*)primitiveId;
- (void)setPrimitiveId:(NSString*)value;




- (NSNumber*)primitiveImageDownloaded;
- (void)setPrimitiveImageDownloaded:(NSNumber*)value;

- (BOOL)primitiveImageDownloadedValue;
- (void)setPrimitiveImageDownloadedValue:(BOOL)value_;




- (NSString*)primitiveImageURLString;
- (void)setPrimitiveImageURLString:(NSString*)value;




- (NSNumber*)primitiveRead;
- (void)setPrimitiveRead:(NSNumber*)value;

- (BOOL)primitiveReadValue;
- (void)setPrimitiveReadValue:(BOOL)value_;




- (NSNumber*)primitiveSaved;
- (void)setPrimitiveSaved:(NSNumber*)value;

- (BOOL)primitiveSavedValue;
- (void)setPrimitiveSavedValue:(BOOL)value_;




- (NSDate*)primitiveTimeStamp;
- (void)setPrimitiveTimeStamp:(NSDate*)value;




- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;




- (NSString*)primitiveUrlString;
- (void)setPrimitiveUrlString:(NSString*)value;





- (DDGStoryFeed*)primitiveFeed;
- (void)setPrimitiveFeed:(DDGStoryFeed*)value;


@end
