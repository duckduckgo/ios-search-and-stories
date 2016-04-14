//
//  DuckDuckGoTests.m
//  DuckDuckGoTests
//
//  Created by Josiah Clumont on 1/02/16.
//
//

#import <XCTest/XCTest.h>
#import "DDGSearchBar.h"

@interface DuckDuckGoTests : XCTestCase

@end

@implementation DuckDuckGoTests

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

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

// Search bar texts
- (void)testTheAbilityToDeterminIfAStringIsAUrl {
    // https:// - Domain
    // http://  - Domain
    // Snow     - Query
    NSString *aUrlString = @"http://google.co.nz";
    NSString *expectedString = @"google.co.nz";
    NSString *actualString   = [DDGSearchBar getTextFromSearchBarText:aUrlString];
    XCTAssertEqualObjects(expectedString, actualString, @"Since it's a http url we should just show the url");
}

- (void)testTheAbilityToDeterminIfAStringIsAQuery {
    NSString *aQueryString   = @"Snow";
    NSString *expectedString = @"Snow";
    NSString *actualString   = [DDGSearchBar getTextFromSearchBarText:aQueryString];
    XCTAssertEqualObjects(expectedString, actualString, @"Since it's a query we should just show the query");
}


@end
