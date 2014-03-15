//
//  UserNestTests.m
//  UserNestTests
//
//  Copyright (c) 2014 UserNest. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UserNest/UserNest.h>


@interface UserNestTests : XCTestCase {
	NSString			*newAccountEmail;
}
@end

@implementation UserNestTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPlainLogin {
	UserNestNetwork	*userNestNetwork = [[UserNestNetwork alloc] initWithUserNestAppID:@"674062da" session:nil];
    userNestNetwork.showErrorMessages = NO;
    [userNestNetwork loginWithUser:@"test@test.com" password:@"Test12321" completionHandler:^(NSDictionary *data) {
        if (data) {
			XCTAssertTrue(data, @"Success:  Logged In");
        } else {
			XCTFail(@"Failed:  Not Logged In");
        }
    }];
}
- (void)testInvalidLogin {
	UserNestNetwork	*userNestNetwork = [[UserNestNetwork alloc] initWithUserNestAppID:@"674062da" session:nil];
    userNestNetwork.showErrorMessages = NO;
    [userNestNetwork loginWithUser:@"test@test.com" password:@"Test12321" completionHandler:^(NSDictionary *data) {
        if (data) {
			XCTFail(@"Failed:  Logged In with BAD PASSWORD");
        } else {
			XCTAssertTrue(YES, @"Success:  Rejected Bad Password");
        }
    }];
}
- (void)testPersistLogin {
	UserNestNetwork	*userNestNetwork = [[UserNestNetwork alloc] initWithUserNestAppID:@"674062da" session:nil];
    userNestNetwork.showErrorMessages = NO;
    [userNestNetwork loginWithUser:@"test@test.com" password:@"Test12321" completionHandler:^(NSDictionary *data) {
        if (data) {
			NSDictionary    *sessionData = data[@"session"];
			NSString		*sessonID = sessionData[@"id"];

			//Create a NEW object, and make sure it can detect they're logged in.
			UserNestNetwork	*userNestNetwork2 = [[UserNestNetwork alloc] initWithUserNestAppID:@"674062da" session:sessonID];
			userNestNetwork2.showErrorMessages = NO;
			[userNestNetwork2 checkLoggedInCompletionHandler:^(Boolean loggedIn) {
				if (loggedIn) {
					XCTAssertTrue(loggedIn, @"Success:  Logged Persisted");
				} else {
					XCTFail(@"Fail:  Login Didn't Persist");
				}
			}];
        } else {
			XCTFail(@"Failed:  Not Logged In");
        }
    }];
}

- (void)testPasswordReset {
	UserNestNetwork	*userNestNetwork = [[UserNestNetwork alloc] initWithUserNestAppID:@"674062da" session:nil];
    userNestNetwork.showErrorMessages = NO;
    [userNestNetwork resetPasswordWithEmail:@"test@test.com" completionHandler:^(Boolean reset) {
        if (reset) {
			XCTAssertTrue(reset, @"Success:  Password Reset Sent");
        } else {
			XCTFail(@"Failed:  Password Reset not sent");
        }
    }];
}

- (void)testGetAccountPolicy {
	UserNestNetwork	*userNestNetwork = [[UserNestNetwork alloc] initWithUserNestAppID:@"674062da" session:nil];
    userNestNetwork.showErrorMessages = NO;
	[userNestNetwork getAccountPolicyCompletionHandler:^(NSDictionary *policy) {
        if (policy) {
			XCTAssertTrue(policy, @"Success:  Got Account Policy");
        } else {
			XCTFail(@"Failed:  No account policy");
        }
    }];
}
- (void)testCreateNewAccount {
	NSMutableDictionary	*newAccountData = [NSMutableDictionary new];
	
    //Make a random account name, simple, based on the time.
	//Damn, hopefully whoever has test.com blocks all emails...they'd have to by now.
    newAccountEmail = [NSString stringWithFormat:@"test+%li@test.com", time(nil)];
    newAccountData[@"email"] = newAccountEmail;
    newAccountData[@"password"] = @"Test12321";
    newAccountData[@"confirmpassword"] = @"Test12321";
    newAccountData[@"tosResponse"] = @"YES";
	
	//Save so Login test next can get it
	[[NSUserDefaults standardUserDefaults] setObject:newAccountEmail forKey:@"LastNewAccountEmail"];

	UserNestNetwork	*userNestNetwork = [[UserNestNetwork alloc] initWithUserNestAppID:@"674062da" session:nil];
    userNestNetwork.showErrorMessages = NO;
    [userNestNetwork createAccount:newAccountData completionHandler:^(NSDictionary *data) {
        if (data) {
            if ([data[@"status"] integerValue]==400) {
                //Really was Error... showErrorMessages = NO means this will get it
				XCTFail(@"Failed:  No account policy, 400 status");
            } else {
				XCTAssertTrue(YES, @"Success:  New Account Created");
            }
        } else {
			XCTFail(@"Failed:  No account policy");
        }
    }];
}
- (void)testLogIntoNewAccount {
	if (newAccountEmail==nil) {
		//Read from userDefaults, in case the 2 tests are run in different sessions.
		newAccountEmail = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastNewAccountEmail"];
	}
	UserNestNetwork	*userNestNetwork = [[UserNestNetwork alloc] initWithUserNestAppID:@"674062da" session:nil];
    userNestNetwork.showErrorMessages = NO;
    [userNestNetwork loginWithUser:newAccountEmail password:@"Test12321" completionHandler:^(NSDictionary *data) {
        if (data) {
			XCTAssertTrue(data, @"Success:  Logged Into New Account");
        } else {
			XCTFail(@"Failed:  Not Logged In");
        }
    }];
}
- (void)testRejectsInvalidSession {
	UserNestNetwork	*userNestNetwork = [[UserNestNetwork alloc] initWithUserNestAppID:@"674062da" session:@"InvalidSessionID"];
    userNestNetwork.showErrorMessages = NO;
    [userNestNetwork checkLoggedInCompletionHandler:^(Boolean loggedIn) {
        if (loggedIn) {
			XCTFail(@"Failed:  Allowed Invalid Session");
        } else {
			XCTAssertTrue(YES, @"Success:  Rejected Invalid Session");
        }
    }];
}

@end
