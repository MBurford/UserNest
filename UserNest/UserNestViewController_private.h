#import <UIKit/UIKit.h>


@interface UserNestViewController (UNPrivate)

- (void)transformToNormal:(float)duration;

- (void)loginSuccess:(NSDictionary*)customData;
- (void)loginFail;

- (void)gotAccountPolicy:(NSDictionary*)newAcct;

- (void)passwordResetSuccess;
- (void)passwordResetFail;

//FOR TESTING
/*- (void)loginWithUser:(NSString*)user password:(NSString*)pass;
- (void)resetPasswordWithEmail:(NSString*)email;
- (void)setUserNestTestCase;
- (void)getAccountPolicy;
- (void)createAccount:(NSDictionary*)acctData;*/

@end
