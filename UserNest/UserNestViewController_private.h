#import <UIKit/UIKit.h>


@interface UserNestViewController (UNPrivate)

- (void)transformToNormal:(float)duration;

- (void)loginSuccess:(NSDictionary*)customData;
- (void)loginFail;

- (void)gotAccountPolicy:(NSDictionary*)newAcct;

- (void)passwordResetSuccess;
- (void)passwordResetFail;

@end
