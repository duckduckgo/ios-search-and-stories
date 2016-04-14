//
//  DDGWebKitViewTests.m
//  DuckDuckGo
//
//  Created by Josiah Clumont on 2/02/16.
//
//

#import <XCTest/XCTest.h>
#import "DDGWebKitWebViewController.h"

@interface DDGWebKitViewTests : XCTestCase

@end

@implementation DDGWebKitViewTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testThatTheAPIMappingsAreOneToOneForReadability {
    // Even tough it's a subclass so it's inheriting, lets test the support
    DDGWebKitWebViewController *webKitVC = [DDGWebKitWebViewController new];
    BOOL doesRespondToCanSwitchToReadablityMode = [webKitVC respondsToSelector:@selector(canSwitchToReadabilityMode)];
    XCTAssertTrue(doesRespondToCanSwitchToReadablityMode, @"DDGWebKitViewController needs to support canSwitchToReadabilityMode");
    
    BOOL doesResponseToSwtichReadabilityMode = [webKitVC respondsToSelector:@selector(switchReadabilityMode:)];
    XCTAssertTrue(doesResponseToSwtichReadabilityMode, @"DDGWebKitViewController needs to support switchReadabilityMode");
}

@end
