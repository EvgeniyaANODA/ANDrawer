//
//  ANDrawerNC.h
//
//  Created by Oksana Kovalchuk on 6/17/14.
//  Copyright (c) 2014 ANODA. All rights reserved.
//

typedef NS_ENUM(NSInteger, ANDrawerOpenDirection)
{
    ANDrawerOpenDirectionFromLeft,
    ANDrawerOpenDirectionFromRight
};

typedef NS_ENUM(NSInteger, ANDrawerTopPin)
{
    ANDrawerTopPinNone,
    ANDrawerTopPinStatusBar,
    ANDrawerTopPinNavigationBar
};

@interface ANDrawerNC : UINavigationController

@property (nonatomic, assign) BOOL useBackground;
@property (nonatomic, assign) UIColor* backgroundColor;
@property (nonatomic, assign) BOOL closeOnPushNewController;
@property (nonatomic, assign) BOOL avoidKeyboard;
@property (nonatomic, assign) ANDrawerTopPin topPin;

//initialization
+ (instancetype)drawerWithView:(UIView*)view width:(CGFloat)width direction:(ANDrawerOpenDirection)direction;

//update state
- (void)toggle;
- (void)updateStateToOpened:(BOOL)isOpen;

@end
