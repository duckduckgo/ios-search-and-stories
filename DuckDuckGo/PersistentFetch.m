//
//  PersistentFetch.m
//  T9
//
//  Created by Chris Heimark on 12/13/11.
//  Copyright (c) 2011 CHS Systems. All rights reserved.
//
// PersistentFetch.m
//
// Copyright (c) 2010 Adam Strzelecki
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "PersistentFetch.h"

@implementation PersistentFetch

@synthesize data;
@synthesize delegate;
@synthesize tag;
@synthesize stream;
@synthesize gotHeaders;

void PersistentFetchReadCallBack(CFReadStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo);
void *CFClientRetain(void *object);
void CFClientRelease(void *object);
CFStringRef CFClientDescribeCopy(void *object);

static int streamCount = 0;
CFReadStreamRef persistentStream = NULL;

+ (void)cleanupPersistentConnections
{
	if(persistentStream != NULL)
	{
		CFReadStreamClose(persistentStream);
		CFRelease(persistentStream);
		persistentStream = NULL;
	}
}

+ (PersistentFetch *)fetchURL:(NSURL *)url delegate:(id<PersistentFetchDelegate>)delegate tag:(NSInteger)tag
{
	return [[[PersistentFetch alloc] initWithURL:url delegate:delegate tag:tag] autorelease];
}

- (id)initWithURL:(NSURL *)_url delegate:(id<PersistentFetchDelegate>)_delegate tag:(NSInteger)_tag
{
	// Copy properties
	self.delegate = _delegate;
	tag = _tag;
	
	CFHTTPMessageRef request = CFHTTPMessageCreateRequest(
														  kCFAllocatorDefault,
														  CFSTR("GET"),
														  (CFURLRef)_url,
														  kCFHTTPVersion1_1);
	if(request != NULL)
	{
		CFHTTPMessageSetHeaderFieldValue(request, CFSTR("Keep-Alive"), CFSTR("30"));
		
		stream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, request);
		
		if(stream != NULL)
		{
			CFStreamClientContext context =
			{
				0, (void *)self,
				CFClientRetain,
				CFClientRelease,
				CFClientDescribeCopy
			};
			CFReadStreamSetClient(stream,
								  kCFStreamEventHasBytesAvailable |
								  kCFStreamEventErrorOccurred |
								  kCFStreamEventEndEncountered,
								  PersistentFetchReadCallBack,
								  &context);
			
			CFReadStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
			
			// In meantime our persistent stream may be closed, check that.
			// If we won't do it, our new stream will raise an error on startup
			// FIXME: This is a bug in CFNetwork!
			if(persistentStream != NULL)
			{
				CFStreamStatus status = CFReadStreamGetStatus(persistentStream);
				if(status == kCFStreamStatusNotOpen || status == kCFStreamStatusClosed || status == kCFStreamStatusError)
				{
					CFReadStreamClose(persistentStream);
					CFRelease(persistentStream);
					persistentStream = NULL;
				}
			}
			
			CFReadStreamSetProperty(stream, kCFStreamPropertyHTTPAttemptPersistentConnection, kCFBooleanTrue);
			CFReadStreamOpen(stream);
			
			if(persistentStream != NULL)
			{
				CFReadStreamClose(persistentStream);
				CFRelease(persistentStream);
				persistentStream = NULL;
			}
			
			streamCount++;
		}
		else
		{
			[delegate fetch:self didFailWithError:NULL];
		}
	}
	else
	{
		[delegate fetch:self didFailWithError:NULL];
	}
	CFRelease(request);
	
	return self;
}

- (void)cancel
{
	CFReadStreamClose(stream);
	// This will release the fetch object
	CFReadStreamSetClient(stream, kCFStreamEventNone, NULL, NULL);
}

- (void)detach
{
	if(streamCount > 1)
	{
		CFReadStreamClose(stream);
	}
	else
	{
		persistentStream = stream;
		CFRetain(persistentStream);
	}
	
	// This will release the fetch object
	CFReadStreamSetClient(stream, kCFStreamEventNone, NULL, NULL);
}

+ (void)releaseStream:(id)streamObject
{
	CFRelease((CFReadStreamRef)streamObject);
}

- (void)dealloc
{
	// FIXME: This fixes case where retain count for stream is 1 and after returning
	// from this function CFNetwork routines crashes, because stream context is freed.
	//CFRelease(stream);
	[PersistentFetch performSelector:@selector(releaseStream:) withObject:(id)stream afterDelay:10];
	
	[(NSObject *)delegate release];
	[data release];
	
	streamCount--;
	
	[super dealloc];
}

#pragma mark -
#pragma mark CFNetwork management

void *CFClientRetain(void *object)
{
	return (void *)[(id)object retain];
}

void CFClientRelease(void *object)
{
	[(id)object release];
}

CFStringRef CFClientDescribeCopy(void *object)
{
	return (CFStringRef)[[(id)object description] retain];
}

void PersistentFetchReadCallBack(CFReadStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo)
{
	PersistentFetch *fetch = (PersistentFetch *)clientCallBackInfo;
	if(!fetch.gotHeaders)
	{
		fetch.gotHeaders = YES;
		CFHTTPMessageRef response = (CFHTTPMessageRef)CFReadStreamCopyProperty(stream, kCFStreamPropertyHTTPResponseHeader);
		if(response == NULL)
		{
			[fetch.delegate fetch:fetch didFailWithError:NULL];
			[fetch cancel];
			return;
		}
		CFStringRef contentLengthString = CFHTTPMessageCopyHeaderFieldValue(response, CFSTR("Content-Length"));
		NSInteger contentLength = NSURLResponseUnknownLength;
		if(contentLengthString != NULL)
		{
			contentLength = CFStringGetIntValue(contentLengthString);
			CFRelease(contentLengthString);
		}
		NSInteger statusCode = CFHTTPMessageGetResponseStatusCode(response);
		CFRelease(response);
		[fetch.delegate fetch:fetch didReceiveStatusCode:statusCode contentLength:contentLength];
	}
	switch(eventType)
	{
		case kCFStreamEventHasBytesAvailable:
			if(fetch.data != nil)
			{
				UInt8 buf[2048];
				CFIndex bytesRead = CFReadStreamRead(stream, buf, sizeof(buf));
				// Returning -1 means an error
				if(bytesRead == -1)
				{
					[fetch.delegate fetch:fetch didFailWithError:NULL];
					[fetch cancel];
				}
				else if(bytesRead > 0)
				{
					[fetch.data appendBytes:buf length:bytesRead];
				}
			}
			break;
		case kCFStreamEventErrorOccurred:
			[fetch.delegate fetch:fetch didFailWithError:NULL];
			[fetch cancel];
			break;
		case kCFStreamEventEndEncountered:
			[fetch.delegate fetchDidFinishLoading:fetch];
			[fetch detach];
			break;
		default:
			break;
	}
}

@end