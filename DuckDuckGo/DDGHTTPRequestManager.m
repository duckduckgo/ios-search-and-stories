//
//  DDGHTTPRequestManager.m
//  DuckDuckGo
//
//  Created by Mic Pringle on 29/05/2014.
//
//

#import "DDGHTTPRequestManager.h"

@implementation DDGHTTPRequestManager

#pragma mark - DDGHTTPRequestManager

+ (void)performRequest:(NSURLRequest *)request
        operationQueue:(NSOperationQueue *)operationQueue
         callbackQueue:(dispatch_queue_t)callbackQueue
               retries:(NSUInteger)retries
               success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
               failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
            expiration:(void (^)())expiration
{
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (retries <= 0) {
            if (failure) {
                failure(operation, error);
            }
        } else {
            [self performRequest:request
                      operationQueue:operationQueue
                   callbackQueue:callbackQueue
                         retries:(retries - 1)
                         success:success
                         failure:failure
                      expiration:expiration];
        }
    }];
    if (expiration) {
        [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:expiration];
    }
    [operation setSuccessCallbackQueue:callbackQueue];
    [operationQueue addOperation:operation];
}

@end
