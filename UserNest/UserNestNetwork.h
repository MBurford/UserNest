//
//  UserNestNetwork.h
//  UserNest
//
//  Created by Michael Burford on 2/26/14.
//  Copyright (c) 2014 Headlight Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UserNest;
@class UserNestNewAccount;

@interface UserNestNetwork : NSObject 

- (void)checkLoggedInThen:(void (^)(Boolean loggedIn))completionHandler;

- (id)initWithUserNestMain:(UserNest*)userNest;
- (id)initWithUserNestNewAccount:(UserNestNewAccount*)userNestNewAccount;

- (void)loginWithUser:(NSString*)user password:(NSString*)pass;

- (void)resetPasswordWithEmail:(NSString*)user;

- (void)getAccountPolicy;

- (void)createAccount:(NSDictionary*)acctData;
- (void)handleNewAccountGotSession:(NSData*)data error:(NSError*)error;

- (void)logoutThen:(void (^)(Boolean invalidated))completionHandler;

@end
