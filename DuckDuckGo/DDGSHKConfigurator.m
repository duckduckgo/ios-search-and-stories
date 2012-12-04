//
//  DDGSHKConfigurator.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/28/12.
//
//

#import "DDGSHKConfigurator.h"

@implementation DDGSHKConfigurator

-(NSString *)appName {
    return @"DuckDuckGo";
}

-(NSString *)appURL {
    return @"http://duckduckgo.com";
}

-(NSString *)sharersPlistName {
    return @"DDGSHKSharers.plist";
}

- (NSString*)facebookAppId {
	return @"208114382551369";
}


// Read It Later - http://readitlaterlist.com/api/signup/ NOW http://getpocket.com/
- (NSString*)readItLaterKey
{
	return @"10907-2685d2ee57602fef03e3da7c";
}

// LinkedIn - https://www.linkedin.com/secure/developer
- (NSString*)linkedInConsumerKey
{
	return @"4yjfvmpaypq4";
}

- (NSString*)linkedInSecret
{
	return @"OXXO1tfvcRg7UaT7";
}

- (NSString*)linkedInCallbackUrl
{
	return @"";
}

// Readability - http://www.readability.com/publishers/api/
- (NSString*)readabilityConsumerKey
{
	return @"DuckDuckGo1";
}

- (NSString*)readabilitySecret
{
	return @"TUXGwuZaamMrKefC4YJWa5AApvfGZ83P";
}

// Evernote - http://www.evernote.com/about/developer/api/
/*	You need to set to sandbox until you get approved by evernote. If you use sandbox, you can use it with special sandbox user account only. You can create it here: https://sandbox.evernote.com/Registration.action
 If you already have a consumer-key and secret which have been created with the old username/password authentication system
 (created before May 2012) you have to get a new consumer-key and secret, as the old one is not accepted by the new authentication
 system.
 // Sandbox
 #define SHKEvernoteHost    @"sandbox.evernote.com"
 
 // Or production
 #define SHKEvernoteHost    @"www.evernote.com"
 */

- (NSString*)evernoteHost
{
	return @"https://sandbox.evernote.com/";
}

- (NSString*)evernoteConsumerKey
{
	return @"duckduckgo";
}

- (NSString*)evernoteSecret
{
	return @"2049b7f87a63686b";
}

// Diigo - http://www.diigo.com/api_keys/new/
- (NSString*)diigoKey
{
	return @"1c521ddb317315b3";
}


@end
