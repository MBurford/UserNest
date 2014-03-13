//
//  UserNestBits.h
//  UserNestTestApp
//
//  Created by Michael Burford on 3/5/14.
//

#import <UIKit/UIKit.h>

@interface UserNestKeychain : NSObject

+ (NSString*)stringForKey:(NSString*)key;
+ (Boolean)setString:(NSString*)object forKey:(NSString*)key;

@end



@interface UIImage (UserNest)

+ (UIImage*)userNestLeftButtonImage:(Boolean)selected;
+ (UIImage*)userNestRightButtonImage:(Boolean)selected;

- (UIImage *)userNestApplyGrayEffect;

@end
