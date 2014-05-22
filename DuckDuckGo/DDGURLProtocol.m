//
//  DDGURLProtocol.m
//  DuckDuckGo
//
//  Created by Mic Pringle on 02/05/2014.
//
//

#import "DDGURLProtocol.h"
#import "DDGUtility.h"

@interface DDGURLProtocol () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSURLConnection *connection;

@end

@implementation DDGURLProtocol

#pragma mark - NSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([[request.URL host] hasSuffix:@"duckduckgo.com"]) {
        if (![NSURLProtocol propertyForKey:@"UserAgentSet" inRequest:request]) {
            return YES;
        }
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    NSMutableURLRequest *request = [self.request mutableCopy];
    if ([[request.URL host] hasSuffix:@"duckduckgo.com"]) {
        [request setValue:[DDGUtility agentDDG] forHTTPHeaderField:@"User-Agent"];
        [NSURLProtocol setProperty:@YES forKey:@"UserAgentSet" inRequest:request];
    }
    self.connection = [NSURLConnection connectionWithRequest:[request copy] delegate:self];
}

- (void)stopLoading
{
    [self.connection cancel];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.client URLProtocol:self didFailWithError:error];
    self.connection = nil;
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self.client URLProtocolDidFinishLoading:self];
    self.connection = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
}

@end
