/*
  UserNestNetwork.h
  UserNest

  Copyright (c) 2014 UserNest. All rights reserved.

  Want to roll your own UI?  Here are the networking functions to let you do that.
 */


#import <UIKit/UIKit.h>

@interface UserNestNetwork : NSObject

/*
 UserNest networking object.  AppID is required, session can be blank @"" or nil.
 */
- (id)initWithUserNestAppID:(NSString*)appID session:(NSString*)existingSession;

/*
 You will need to have passed in a session in the init above, otherwise the 
 check will immediately call the completionHander(NO).
 */
- (void)checkIsLoggedInCompletionHandler:(void (^)(Boolean loggedIn))completionHandler;

/*
 User is either the email address, or username, depending on your UserNest login policies.  Email is the default.
 nil for completionHandler data means logging in failed.
 */
- (void)loginWithUser:(NSString*)user password:(NSString*)pass completionHandler:(void (^)(NSDictionary *data))completionHandler;

/*
 Does what it says.
 */
- (void)resetPasswordWithEmail:(NSString*)user completionHandler:(void (^)(Boolean reset))completionHandler;

/*
 Account policy is mostly for creating new accounts, but you can also check it to see 
 if the user should login with an email or a username.
 nil for completionHandler policy means getting the policy failed.
 */
- (void)getAccountPolicyCompletionHandler:(void (^)(NSDictionary *policy))completionHandler;

/*
 The dictionary must have all the values for creating a new account.
 nil for completionHandler result data means creating the account failed.
 
 If you have set to Not show error messages, data will be returned even if there was a problem 
 creating the account (like an invalid password) you will need to check the data contents to
 see if creating the account succeeded or failed.
 if ([data[@"status"] integerValue]==400) { //Error...
 */
- (void)createAccount:(NSDictionary*)acctData completionHandler:(void (^)(NSDictionary *data))completionHandler;

/*
 You should always delete the local session, even if invalidating the server's session failed.
 (Such as because of being in Airplane mode when Logout is called.)
 */
- (void)logoutCompletionHandler:(void (^)(Boolean invalidatedServer))completionHandler;


/*
 For Testing, to hide alert error messages.  Default is YES to show them
 */
@property (atomic, assign) Boolean showErrorMessages;


@end
