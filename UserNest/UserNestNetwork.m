//
//  UserNestNetwork.m
//  UserNest
//
//  Created by Michael Burford on 2/26/14.
//  Copyright (c) 2014 Headlight Software, Inc. All rights reserved.
//

#import "UserNest.h"
#import "UserNest_private.h"
#import "UserNestNewAccount.h"
#import "UserNestNetwork.h"
#import "UserNestBits.h"

@implementation UserNestNetwork {
    NSString    *loginUser;
    NSString    *loginPass;

    NSString    *resetEmail;

	NSDictionary	*newAccountData;

    UserNest    *mainUserNest;
    UserNestNewAccount    *mainUserNestNewAccount;
}

/////////////////////////////////////////////////////////////////////////
- (id)initWithUserNestMain:(UserNest*)userNest {
    self = [super init];
    if (self) {
        mainUserNest = [userNest retain];
    }
    return self;
}
- (id)initWithUserNestNewAccount:(UserNestNewAccount*)userNestNewAccount {
    self = [super init];
    if (self) {
        mainUserNestNewAccount = [userNestNewAccount retain];
    }
    return self;
}

//Used a lot of places, so one convert that shows errors---------------------
- (NSDictionary*)jsonToDictionary:(NSData*)data errorAlerts:(Boolean)errorAlerts {
    //Couldn't get anything--don't bother trying to convert and show an appropriate message
    if (!data) {
		if (errorAlerts) {
			UIAlertView		*errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
																  message:NSLocalizedString(@"Unable to connect to server, check your Internet connection", nil)
																 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[errorAlert show];
		}
		return nil;
    }
    
    NSError         *jsonError = nil;
    NSString		*jString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSLog(@"jString: %@", jString);
    NSDictionary	*JSON = [NSJSONSerialization JSONObjectWithData:[jString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&jsonError];
    
    if (jsonError || !JSON) {
		if (errorAlerts) {
			UIAlertView		*errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
																  message:NSLocalizedString(@"Unable to process reply, check your Internet connection", nil)
																 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[errorAlert show];
		}
		return nil;
    }
    
    //If the status on the reply isn't 200, that's an error--all can be handled here too.
	if (JSON[@"status"] && [JSON[@"status"] intValue]!=200) {
		if (errorAlerts) {
			UIAlertView		*errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
																  message:NSLocalizedString(JSON[@"msg"], nil)
																 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[errorAlert show];
		}
		return nil;
	}

    return JSON;
}

/////////////////////////////////////////////////////////////////////////
//Logout is an easy case
- (void)logoutThen:(void (^)(Boolean invalidatedServer))completionHandler {
    if (mainUserNest.userNestSession) {
        //First get the Session.
        NSURL                   *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://secure.umsdb.net/api/v1/frontend/auth/logout?appId=%@&sessionId=%@",
                                                             mainUserNest.userNestAppID, mainUserNest.userNestSession]];
        NSMutableURLRequest     *request = [NSMutableURLRequest requestWithURL:URL];
        
        [request setHTTPMethod:@"POST"];
        
        //Easy one, can simply Post to get the session
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                         //Can show UI things, so fire on the main thread...
                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                             [self handleLogout:data error:error then:completionHandler];

                                                                         });
                                                                     }];
        [task resume];
    }
}
- (void)handleLogout:(NSData*)data error:(NSError*)error then:(void (^)(Boolean invalidatedServer))completionHandler {
    //ANY RESPONSE counts to invalidate client.
    [UserNestKeychain setString:@"" forKey:@"sessionID"];
    mainUserNest.userNestSession = nil;

    //Would be weird, but can't invalidate the session on the server without
	NSDictionary	*JSON = [self jsonToDictionary:data errorAlerts:NO];
    if (JSON) {
        if (completionHandler) {
            completionHandler(YES);
        }
        return;
    }

    if (completionHandler) {
        completionHandler(NO);
    }
}

- (void)checkLoggedInThen:(void (^)(Boolean loggedIn))completionHandler {
	NSURL                   *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://secure.umsdb.net/api/v1/frontend/auth/session/%@?appId=%@",
														 mainUserNest.userNestSession, mainUserNest.userNestAppID]];

    NSMutableURLRequest     *request = [NSMutableURLRequest requestWithURL:URL];
	
	NSURLSessionDataTask *test = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                     //Can show UI things, so fire on the main thread...
                                                                     dispatch_async(dispatch_get_main_queue(), ^{
																		 [self handleCheckLoggedIn:data error:error then:completionHandler];
																	 });
                                                                 }];
    [test resume];
}
- (void)handleCheckLoggedIn:(NSData*)data error:(NSError*)error then:(void (^)(Boolean loggedIn))completionHandler {
	NSDictionary	*JSON = [self jsonToDictionary:data errorAlerts:NO];
    if (JSON) {
		//userID having a value means they're logged in.
		if ([JSON[@"userId"] length]>0) {
			completionHandler(YES);
			return;
		}
	}
    //NOT logged in, clear session things
    [UserNestKeychain setString:@"" forKey:@"sessionID"];
    mainUserNest.userNestSession = nil;
    
	completionHandler(NO);
}


//////////////////////////////////////////////////////////////////////
- (void)getAccountPolicy {
	NSURL                   *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://secure.umsdb.net/api/v1/frontend/auth/policy?appId=%@",
														 mainUserNest.userNestAppID]];
    NSMutableURLRequest     *request = [NSMutableURLRequest requestWithURL:URL];
	
	NSURLSessionDataTask *test = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                     //Can show UI things, so fire on the main thread...
                                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                                         [self handleGotNewUserPolicy:data error:error];
                                                                     });
                                                                 }];
    [test resume];
	
}
- (void)handleGotNewUserPolicy:(NSData*)data error:(NSError*)error {
    NSDictionary	*JSON = [self jsonToDictionary:data errorAlerts:YES];
    if (JSON) {
        [mainUserNest gotAccountPolicy:JSON];
        return;
    }
    if (userNestTestCase) {
        [mainUserNest gotAccountPolicy:nil];
    }
}

//////////////////////////////////////////////////////////////////////
- (void)getSessionForApp:(NSString*)appID then:(void (^)(NSData *data, NSError *error))completionHandler {
	//Get the session
    NSURL                   *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://secure.umsdb.net/api/v1/frontend/auth/session?appId=%@",
                                                         appID]];
    NSMutableURLRequest     *request = [NSMutableURLRequest requestWithURL:URL];
    
    [request setHTTPMethod:@"POST"];
    
    //Easy one, can simply Post to get the session
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                     //Can show UI things, so fire on the main thread...
                                                                     dispatch_async(dispatch_get_main_queue(), ^{
																		 completionHandler(data, error);
                                                                     });
                                                                 }];
    [task resume];
}

//////////////////////////////////////////////////////////////////////
- (void)loginWithUser:(NSString*)user password:(NSString*)pass {
    loginUser = [user retain];
    loginPass = [pass retain];
	
	[self getSessionForApp:mainUserNest.userNestAppID then:^(NSData *data, NSError *error) {
		//Can show UI things, so fire on the main thread...
		dispatch_async(dispatch_get_main_queue(), ^{
			[self handleLoginGotSession:data error:error];
		});
	}];
}

- (void)handleLoginGotSession:(NSData*)data error:(NSError*)error {
	if (data==nil && error==nil && mainUserNest.userNestSession!=nil) {
		//Already got a session ID, re-use it...
	} else {
		NSDictionary	*JSON = [self jsonToDictionary:data errorAlerts:YES];
		if (!JSON) {
			[mainUserNest transformToNormal:0.33];
			return;
		}
		mainUserNest.userNestSession = JSON[@"id"];
	}
	
    //Second step, use the session and send to login
    NSURL                   *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://secure.umsdb.net/api/v1/frontend/auth/with-password?appId=%@&sessionId=%@",
                                                         mainUserNest.userNestAppID, mainUserNest.userNestSession]];
    NSMutableURLRequest     *request = [NSMutableURLRequest requestWithURL:URL];
    
    NSDictionary            *contentDic = @{@"email": loginUser, @"password": loginPass, @"tosResponse": @"YES"};
    NSError                 *jsonError = nil;
    NSData                  *contentData = [NSJSONSerialization dataWithJSONObject:contentDic options:0 error:&jsonError];
	
    if (jsonError) {
		UIAlertView		*errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
															  message:NSLocalizedString(@"Unable to package data to login", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[errorAlert show];
        [mainUserNest transformToNormal:0.33];
		return;
    }
	
    //Add the data to the request, and post it.
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[contentData length]] forHTTPHeaderField:@"Content-Length"];
    
    NSURLSessionUploadTask *task = [[NSURLSession sharedSession] uploadTaskWithRequest:request fromData:contentData
                                                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                         //Can show UI things, so fire on the main thread...
                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                             [self handleLoginGotLoginReply:data error:error];
                                                                         });
                                                                     }];
    [task resume];
}
- (void)handleLoginGotLoginReply:(NSData*)data error:(NSError*)error {
    NSDictionary	*JSON = [self jsonToDictionary:data errorAlerts:!userNestTestCase];
    if (!JSON) {
        [mainUserNest transformToNormal:0.33];
        if (userNestTestCase) [mainUserNest loginFail];
		return;
    }
    NSLog(@"LoginReply:%@", JSON);
    
    NSDictionary    *userDic = JSON[@"user"];
    
	//Has been deleted?
    if (userDic[@"isDeleted"] && [userDic[@"isDeleted"] boolValue]) {
		UIAlertView		*errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
															  message:NSLocalizedString(@"Could not log in, account deleted", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[errorAlert show];
        [mainUserNest transformToNormal:0.33];
        if (userNestTestCase) [mainUserNest loginFail];
		return;
    }
	//Has been disabled?
    if (userDic[@"acceptNew"] && ![userDic[@"acceptNew"] boolValue]) {
		UIAlertView		*errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
															  message:NSLocalizedString(@"Could not log in, account disabled", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[errorAlert show];
        [mainUserNest transformToNormal:0.33];
        if (userNestTestCase) [mainUserNest loginFail];
		return;
    }
	
	[mainUserNest loginSuccess:JSON];
}


/////////////////////////////////////////////////////////////////////////////
- (void)createAccount:(NSDictionary*)acctData {
	newAccountData = [acctData retain];
	
	[self getSessionForApp:mainUserNestNewAccount.userNestAppID then:^(NSData *data, NSError *error) {
		//Can show UI things, so fire on the main thread...
		dispatch_async(dispatch_get_main_queue(), ^{
			[self handleNewAccountGotSession:data error:error];
		});
	}];
}

- (void)handleNewAccountGotSession:(NSData*)data error:(NSError*)error {
	if (data==nil && error==nil && mainUserNestNewAccount.userNestSession!=nil) {
		//Already got a session ID, re-using it...
	} else {
		NSDictionary	*JSON = [self jsonToDictionary:data errorAlerts:!userNestTestCase];
		if (!JSON) {
			[mainUserNestNewAccount newAccountFailed];
			return;
		}
		mainUserNestNewAccount.userNestSession = JSON[@"id"];
	}
	
	NSURL                   *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://secure.umsdb.net/api/v1/frontend/auth/new-user?appId=%@&sessionId=%@",
                                                         mainUserNestNewAccount.userNestAppID, mainUserNestNewAccount.userNestSession]];
    NSMutableURLRequest     *request = [NSMutableURLRequest requestWithURL:URL];
    
    NSError                 *jsonError = nil;
    NSData                  *contentData = [NSJSONSerialization dataWithJSONObject:newAccountData options:0 error:&jsonError];
	
    if (jsonError) {
		UIAlertView		*errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
															  message:NSLocalizedString(@"Unable to package data to create account", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[errorAlert show];
		return;
    }
	
    //Add the data to the request, and post it.
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[contentData length]] forHTTPHeaderField:@"Content-Length"];
    
    NSURLSessionUploadTask *task = [[NSURLSession sharedSession] uploadTaskWithRequest:request fromData:contentData
                                                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                         //Can show UI things, so fire on the main thread...
                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                             [self handleNewAccountReply:data error:error];
                                                                         });
                                                                     }];
    [task resume];

}
- (void)handleNewAccountReply:(NSData*)data error:(NSError*)error {
	NSDictionary	*JSON = [self jsonToDictionary:data errorAlerts:!userNestTestCase];
	if (!JSON) {
		[mainUserNestNewAccount newAccountFailed];
		return;
	}
	
	//Got here, should be OK!
	[mainUserNestNewAccount newAccountSuccess];
}

/////////////////////////////////////////////////////////////////////////////

- (void)resetPasswordWithEmail:(NSString*)email {
    resetEmail = [email retain];
    
	[self getSessionForApp:mainUserNest.userNestAppID then:^(NSData *data, NSError *error) {
		//Can show UI things, so fire on the main thread...
		dispatch_async(dispatch_get_main_queue(), ^{
			[self handlePasswordResetGotSession:data error:error];
		});
	}];
}

- (void)handlePasswordResetGotSession:(NSData*)data error:(NSError*)error {
	if (data==nil && error==nil && mainUserNest.userNestSession!=nil) {
		//Already got a session ID, re-using it...
	} else {
		NSDictionary	*JSON = [self jsonToDictionary:data errorAlerts:!userNestTestCase];
		if (!JSON) {
			[mainUserNest passwordResetFail];
			return;
		}
		mainUserNest.userNestSession = JSON[@"id"];
	}
	
	NSURL                   *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://secure.umsdb.net/api/v1/frontend/auth/request-pwreset?appId=%@&sessionId=%@",
                                                         mainUserNest.userNestAppID, mainUserNest.userNestSession]];
    NSMutableURLRequest     *request = [NSMutableURLRequest requestWithURL:URL];
    
    NSDictionary            *passwordResetData = @{@"email": resetEmail };
    NSError                 *jsonError = nil;
    NSData                  *contentData = [NSJSONSerialization dataWithJSONObject:passwordResetData options:0 error:&jsonError];
	
    if (jsonError) {
		UIAlertView		*errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
															  message:NSLocalizedString(@"Unable to package data to reset password", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[errorAlert show];
		return;
    }
	
    //Add the data to the request, and post it.
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[contentData length]] forHTTPHeaderField:@"Content-Length"];
    
    NSURLSessionUploadTask *task = [[NSURLSession sharedSession] uploadTaskWithRequest:request fromData:contentData
                                                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                         //Can show UI things, so fire on the main thread...
                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                             [self handlePasswordResetReply:data error:error];
                                                                         });
                                                                     }];
    [task resume];
    
}
- (void)handlePasswordResetReply:(NSData*)data error:(NSError*)error {
	NSDictionary	*JSON = [self jsonToDictionary:data errorAlerts:!userNestTestCase];
	if (!JSON) {
		[mainUserNest passwordResetFail];
		return;
	}
	
	//Got here, should be OK!
	[mainUserNest passwordResetSuccess];
}


@end
