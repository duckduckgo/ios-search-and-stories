//
//  NSManagedObjectContext+NSManagedObjectContext_DDG.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/9/12.
//
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (DDG)

- (NSSet *)fetchObjectsForEntityName:(NSString *)newEntityName
                       withPredicate:(id)stringOrPredicate, ...;

@end
