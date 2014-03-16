//
//  UserNestNetwork.m
//  UserNest
//
//  Copyright (c) 2014 UserNest. All rights reserved.
//

#import "UserNestNetwork.h"
#import "UserNestBits.h"

@implementation UserNestNetwork {
	NSString	*userNestAppID;
	NSString	*userNestSession;
    NSString    *loginUser;
    NSString    *loginPass;

    NSString    *resetEmail;

	NSDictionary	*newAccountData;
}

/////////////////////////////////////////////////////////////////////////

- (id)initWithUserNestAppID:(NSString*)appID session:(NSString*)existingSession {
    self = [super init];
    if (self) {
        userNestAppID = [appID retain];
		userNestSession = [existingSession retain];
        self.showErrorMessages = YES;
    }
    return self;
}

//Used a lot of places, so one convert that shows errors if needed---------------------
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
																  message:NSLocalizedString(@"Unable to process reply", nil)
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
- (void)logoutCompletionHandler:(void (^)(Boolean invalidatedServer))completionHandler {
    if (userNestSession) {
        //First get the Session.
        NSURL                   *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://secure.umsdb.net/api/v1/frontend/auth/logout?appId=%@&sessionId=%@",
                                                             userNestAppID, userNestSession]];
        NSMutableURLRequest     *request = [NSMutableURLRequest requestWithURL:URL];
        
        [request setHTTPMethod:@"POST"];
        
        //Easy one, can simply Post to get the session
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                         //Can show UI things, so fire on the main thread...
                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                             [self handleLogout:data error:error completionHandler:completionHandler];
                                                                         });
                                                                     }];
        [task resume];
    }
}
- (void)handleLogout:(NSData*)data error:(NSError*)error completionHandler:(void (^)(Boolean invalidatedServer))completionHandler {
    //Would be weird, but can't invalidate the session on the server;
    //Always delete the local session, even if invalidating failed
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

/////////////////////////////////////////////////////////////////////////
//See if the current userNestSession is valid & logged in.
- (void)checkIsLoggedInCompletionHandler:(void (^)(Boolean loggedIn))completionHandler {
	NSURL                   *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://secure.umsdb.net/api/v1/frontend/auth/session/%@?appId=%@",
														 userNestSession, userNestAppID]];

    NSMutableURLRequest     *request = [NSMutableURLRequest requestWithURL:URL];
	
	NSURLSessionDataTask *test = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                     //Can show UI things, so fire on the main thread...
                                                                     dispatch_async(dispatch_get_main_queue(), ^{
																		 [self handleCheckLoggedIn:data error:error completionHandler:completionHandler];
																	 });
                                                                 }];
    [test resume];
}
- (void)handleCheckLoggedIn:(NSData*)data error:(NSError*)error completionHandler:(void (^)(Boolean loggedIn))completionHandler {
	NSDictionary	*JSON = [self jsonToDictionary:data errorAlerts:NO];
    if (JSON) {
		//userID having a value means they're logged in.
		if ([JSON[@"userId"] length]>0) {
			completionHandler(YES);
			return;
		}
	}
	completionHandler(NO);
}

//////////////////////////////////////////////////////////////////////
//Used by several of them, to get a session for the next step
- (void)getSessionForApp:(NSString*)appID completionHandler:(void (^)(NSData *data, NSError *error))completionHandler {
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
//Account Policy, mainly for creating new accounts, but also can tell if they use Usernames to login instead of emails.
- (void)getAccountPolicyCompletionHandler:(void (^)(NSDictionary *policy))completionHandler {
	NSURL                   *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://secure.umsdb.net/api/v1/frontend/auth/policy?appId=%@",
														 userNestAppID]];
    NSMutableURLRequest     *request = [NSMutableURLRequest requestWithURL:URL];
	
	NSURLSessionDataTask *test = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                     //Can show UI things, so fire on the main thread...
                                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                                         [self handleGotNewUserPolicy:data error:error completionHandler:completionHandler];
                                                                     });
                                                                 }];
    [test resume];
	
}
- (void)handleGotNewUserPolicy:(NSData*)data error:(NSError*)error completionHandler:(void (^)(NSDictionary *policy))completionHandler {
    NSDictionary	*JSON = [self jsonToDictionary:data errorAlerts:YES];
    if (JSON) {
		completionHandler(JSON);
        return;
    }
	completionHandler(nil);
}

//////////////////////////////////////////////////////////////////////
//Biggie, login!
- (void)loginWithUser:(NSString*)user password:(NSString*)pass completionHandler:(void (^)(NSDictionary *data))completionHandler {
    loginUser = [user retain];
    loginPass = [pass retain];
	
	[self getSessionForApp:userNestAppID completionHandler:^(NSData *data, NSError *error) {
		//Can show UI things, so fire on the main thread...
		dispatch_async(dispatch_get_main_queue(), ^{
			[self handleLoginGotSession:data error:error completionHandler:completionHandler];
		});
	}];
}

- (void)handleLoginGotSession:(NSData*)data error:(NSError*)error completionHandler:(void (^)(NSDictionary *data))completionHandler {
	if (data==nil && error==nil && userNestSession!=nil) {
		//Already got a session ID, re-use it...
	} else {
		NSDictionary	*JSON = [self jsonToDictionary:data errorAlerts:YES];
		if (!JSON) {
			completionHandler(nil);
			return;
		}
		userNestSession = [JSON[@"id"] retain];
	}
	
    //Second step, use the session and send to login
    NSURL                   *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://secure.umsdb.net/api/v1/frontend/auth/with-password?appId=%@&sessionId=%@",
                                                         userNestAppID, userNestSession]];
    NSMutableURLRequest     *request = [NSMutableURLRequest requestWithURL:URL];
    
    NSDictionary            *contentDic = @{@"email": loginUser, @"password": loginPass, @"tosResponse": @"YES"};
    NSError                 *jsonError = nil;
    NSData                  *contentData = [NSJSONSerialization dataWithJSONObject:contentDic options:0 error:&jsonError];
	
    if (jsonError) {
		UIAlertView		*errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
															  message:NSLocalizedString(@"Unable to package data to login", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[errorAlert show];
		completionHandler(nil);
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
                                                                             [self handleLoginGotLoginReply:data error:error completionHandler:completionHandler];
                                                                         });
                                                                     }];
    [task resume];
}
- (void)handleLoginGotLoginReply:(NSData*)data error:(NSError*)error completionHandler:(void (^)(NSDictionary *data))completionHandler {
    NSDictionary	*JSON = [self jsonToDictionary:data errorAlerts:self.showErrorMessages];
    if (!JSON) {
		completionHandler(nil);
		return;
    }
    NSLog(@"LoginReply:%@", JSON);
    
    NSDictionary    *userDic = JSON[@"user"];
    
	//Has been deleted?
    if (userDic[@"isDeleted"] && [userDic[@"isDeleted"] boolValue]) {
		UIAlertView		*errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
															  message:NSLocalizedString(@"Could not log in, account deleted", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[errorAlert show];
		completionHandler(nil);
		return;
    }
	//Has been disabled?
    if (userDic[@"acceptNew"] && ![userDic[@"acceptNew"] boolValue]) {
		UIAlertView		*errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
															  message:NSLocalizedString(@"Could not log in, account disabled", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[errorAlert show];
		completionHandler(nil);
		return;
    }
	
	completionHandler(JSON);
}


/////////////////////////////////////////////////////////////////////////////
//Create an account.  Must have all required fields in the acctData keyed by the JSON expected by the server.
- (void)createAccount:(NSDictionary*)acctData completionHandler:(void (^)(NSDictionary *data))completionHandler {
	newAccountData = [acctData retain];
	
	[self getSessionForApp:userNestAppID completionHandler:^(NSData *data, NSError *error) {
		//Can show UI things, so fire on the main thread...
		dispatch_async(dispatch_get_main_queue(), ^{
			[self handleNewAccountGotSession:data error:error completionHandler:completionHandler];
		});
	}];
}

- (void)handleNewAccountGotSession:(NSData*)data error:(NSError*)error completionHandler:(void (^)(NSDictionary *data))completionHandler {
	if (data==nil && error==nil && userNestSession!=nil) {
		//Already got a session ID, re-using it...
	} else {
		NSDictionary	*JSON = [self jsonToDictionary:data errorAlerts:self.showErrorMessages];
		if (!JSON) {
            completionHandler(nil);
			return;
		}
		userNestSession = [JSON[@"id"] retain];
	}
	
	NSURL                   *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://secure.umsdb.net/api/v1/frontend/auth/new-user?appId=%@&sessionId=%@",
                                                         userNestAppID, userNestSession]];
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
                                                                             [self handleNewAccountReply:data error:error completionHandler:completionHandler];
                                                                         });
                                                                     }];
    [task resume];

}
- (void)handleNewAccountReply:(NSData*)data error:(NSError*)error completionHandler:(void (^)(NSDictionary *data))completionHandler {
	NSDictionary	*JSON = [self jsonToDictionary:data errorAlerts:self.showErrorMessages];
	if (!JSON) {
        completionHandler(nil);
		return;
	}
	
	//Got here, should be OK!
    completionHandler(JSON);
}

/////////////////////////////////////////////////////////////////////////////
//Easier one, ask it to send a password reset email
- (void)resetPasswordWithEmail:(NSString*)email completionHandler:(void (^)(Boolean reset))completionHandler {
    resetEmail = [email retain];
    
	[self getSessionForApp:userNestAppID completionHandler:^(NSData *data, NSError *error) {
		//Can show UI things, so fire on the main thread...
		dispatch_async(dispatch_get_main_queue(), ^{
			[self handlePasswordResetGotSession:data error:error completionHandler:completionHandler];
		});
	}];
}

- (void)handlePasswordResetGotSession:(NSData*)data error:(NSError*)error completionHandler:(void (^)(Boolean reset))completionHandler {
	if (data==nil && error==nil && userNestSession!=nil) {
		//Already got a session ID, re-using it...
	} else {
		NSDictionary	*JSON = [self jsonToDictionary:data errorAlerts:self.showErrorMessages];
		if (!JSON) {
            completionHandler(NO);
			return;
		}
		userNestSession = [JSON[@"id"] retain];
	}
	
	NSURL                   *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://secure.umsdb.net/api/v1/frontend/auth/request-pwreset?appId=%@&sessionId=%@",
                                                         userNestAppID, userNestSession]];
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
                                                                             [self handlePasswordResetReply:data error:error completionHandler:completionHandler];
                                                                         });
                                                                     }];
    [task resume];
    
}
- (void)handlePasswordResetReply:(NSData*)data error:(NSError*)error completionHandler:(void (^)(Boolean reset))completionHandler {
	NSDictionary	*JSON = [self jsonToDictionary:data errorAlerts:self.showErrorMessages];
	if (!JSON) {
        completionHandler(NO);
		return;
	}
	
	//Got here, should be OK!
	completionHandler(YES);
}


@end
