//
//  BlurBehindTransition.h
//  z-Overlaytest
//
//  Created by Michael Burford on 2/4/14.
//  Copyright (c) 2014 Headlight Software, Inc. All rights reserved.
//
// Found some starting code here, but adapted a lot
// www.doubleencore.com/2013/09/ios-7-custom-transitions/

#import <UIKit/UIKit.h>


typedef NS_ENUM(NSInteger, BBDirection) {
    BBDirectionUp,
    BBDirectionDown,
};

@interface BlurBehindTransitioningDelegate : NSObject <UIViewControllerTransitioningDelegate>
@property (nonatomic, assign) BBDirection     direction;
@end


@interface BlurBehindAnimatedTransitioning : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, strong) UIImageView   *blurBG;
@property (nonatomic, assign) Boolean       reverse;
@property (nonatomic, assign) BBDirection     direction;

@end
