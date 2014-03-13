//
//  BlurBehindTransition.m
//  z-Overlaytest
//
//  Created by Michael Burford on 2/4/14.
//  Copyright (c) 2014 Headlight Software, Inc. All rights reserved.
//

#import "BlurBehindTransition.h"
#import "UserNestBits.h"


@implementation BlurBehindTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    BlurBehindAnimatedTransitioning *transitioning = [BlurBehindAnimatedTransitioning new];
    transitioning.direction = self.direction;
    return transitioning;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    BlurBehindAnimatedTransitioning *transitioning = [BlurBehindAnimatedTransitioning new];
    transitioning.reverse = YES;
    transitioning.direction = self.direction;
    return transitioning;
}

@end

static NSTimeInterval const BlurBehindAnimatedTransitionDuration = 0.65f;
static NSInteger const BlurViewTag = 0x426c7572; //"Blur"

@implementation BlurBehindAnimatedTransitioning

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController    *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController    *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView              *container = [transitionContext containerView];
    
    CGRect      screenRect = fromViewController.view.bounds;
    
    if (self.reverse) {
        //Animating back out
        [container insertSubview:toViewController.view belowSubview:fromViewController.view];

        if (!self.blurBG) {
            self.blurBG = (id)[fromViewController.view viewWithTag:BlurViewTag];
        }
    } else {
        //STARTING...
        if (self.direction==BBDirectionUp) {
            toViewController.view.frame = CGRectMake(0, screenRect.size.height, screenRect.size.width, screenRect.size.height);
        } else {
            toViewController.view.frame = CGRectMake(0, -screenRect.size.height, screenRect.size.width, screenRect.size.height);
        }
        [container addSubview:toViewController.view];
        
        toViewController.view.clipsToBounds = NO;
        toViewController.view.backgroundColor = [UIColor clearColor];

        [self addBlurring:toViewController.view fromView:fromViewController.view];
    }
    
    //Animate, moving the view in, and moving the background blur image opposite so it stays in place & fades in
    [UIView animateKeyframesWithDuration:BlurBehindAnimatedTransitionDuration*0.80 delay:0 options:0 animations:^{
        if (self.reverse) {
            if (self.direction==BBDirectionUp) {
                fromViewController.view.frame = CGRectMake(0, screenRect.size.height, screenRect.size.width, screenRect.size.height);
                self.blurBG.frame = CGRectMake(0, -screenRect.size.height, fromViewController.view.frame.size.width, fromViewController.view.frame.size.height);
            } else {
                fromViewController.view.frame = CGRectMake(0, -screenRect.size.height, screenRect.size.width, screenRect.size.height);
                self.blurBG.frame = CGRectMake(0, screenRect.size.height, fromViewController.view.frame.size.width, fromViewController.view.frame.size.height);
            }
            self.blurBG.alpha = 0.0;
        } else {
            toViewController.view.frame = CGRectMake(0, -5, screenRect.size.width, screenRect.size.height);
            self.blurBG.frame = CGRectMake(0, 5, toViewController.view.frame.size.width, toViewController.view.frame.size.height);
            self.blurBG.alpha = 1.0;
        }
    } completion:^(BOOL finished) {
        
        [UIView animateKeyframesWithDuration:BlurBehindAnimatedTransitionDuration*0.20 delay:0 options:0 animations:^{
            if (self.reverse) {
                if (self.direction==BBDirectionUp) {
                    fromViewController.view.frame = CGRectMake(0, screenRect.size.height, screenRect.size.width, screenRect.size.height);
                    self.blurBG.frame = CGRectMake(0, -screenRect.size.height, fromViewController.view.frame.size.width, fromViewController.view.frame.size.height);
                } else {
                    fromViewController.view.frame = CGRectMake(0, -screenRect.size.height, screenRect.size.width, screenRect.size.height);
                    self.blurBG.frame = CGRectMake(0, screenRect.size.height, fromViewController.view.frame.size.width, fromViewController.view.frame.size.height);
                }
                self.blurBG.alpha = 0.0;
            } else {
                toViewController.view.frame = CGRectMake(0, 0, screenRect.size.width, screenRect.size.height);
                self.blurBG.frame = CGRectMake(0, 0, toViewController.view.frame.size.width, toViewController.view.frame.size.height);
                self.blurBG.alpha = 1.0;
            }
        } completion:^(BOOL finished) {
            if (self.reverse && finished) {
                [self.blurBG removeFromSuperview];
                self.blurBG = nil;
            }
            [transitionContext completeTransition:finished];
        }];

 /*       if (self.reverse && finished) {
            [self.blurBG removeFromSuperview];
            self.blurBG = nil;
        }
        [transitionContext completeTransition:finished];*/
    }];
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return BlurBehindAnimatedTransitionDuration;
}

- (void)addBlurring:(UIView*)toView fromView:(UIView*)fromView {
    CGRect      screenRect = fromView.bounds;

    self.blurBG = [[UIImageView alloc] initWithFrame:fromView.bounds];
    if (self.direction==BBDirectionUp) {
        self.blurBG.frame = CGRectMake(0, -screenRect.size.height, toView.frame.size.width, toView.frame.size.height);
    } else {
        self.blurBG.frame = CGRectMake(0, screenRect.size.height, toView.frame.size.width, toView.frame.size.height);
    }
	self.blurBG.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.blurBG.alpha = 0.0;
    self.blurBG.backgroundColor = [UIColor blueColor];
    self.blurBG.tag = BlurViewTag;
    [toView addSubview:self.blurBG];
    [toView sendSubviewToBack:self.blurBG];

    //Get the previous view's contents as an image, with blurring applied.
    UIGraphicsBeginImageContextWithOptions(fromView.bounds.size, YES, 0.0);
    [fromView.layer renderInContext:UIGraphicsGetCurrentContext()];
    self.blurBG.image = [UIGraphicsGetImageFromCurrentImageContext() userNestApplyGrayEffect];
    UIGraphicsEndImageContext();
}

@end
