//
//  ANDrawerNC.m
//
//  Created by Oksana Kovalchuk on 6/17/14.
//  Copyright (c) 2014 ANODA. All rights reserved.
//

#import "ANDrawerNC.h"
#import "MSSPopMasonry.h"
#import "FrameAccessor.h"
#import "ReactiveCocoa.h"

#import "POP+MCAnimate.h"


static CGFloat const kDefaultDrawerVelocityTrigger = 350;
static CGFloat const kStatusBarHeight = 20;


@interface ANDrawerNC () <UIGestureRecognizerDelegate>

@property (nonatomic, assign) BOOL isOpen;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) MASConstraint* animatedConstraint;
@property (nonatomic, strong) MASConstraint* topConstraint;

@property (nonatomic, strong) UIView *drawerView;
@property (nonatomic, assign) CGFloat drawerWidth;
@property (nonatomic, assign) ANDrawerOpenDirection openDirection;
@property (nonatomic, strong) UIPanGestureRecognizer* panGesure;

@end

@implementation ANDrawerNC

+ (instancetype)drawerWithView:(UIView*)view width:(CGFloat)width direction:(ANDrawerOpenDirection)direction
{
    ANDrawerNC* instance = [ANDrawerNC new];
    [instance setupDrawerView:view width:width openDirection:direction];
    return instance;
}

#pragma mark - Setters/Getters

- (void)setupDrawerView:(UIView *)drawerView width:(CGFloat)drawerWidth openDirection:(ANDrawerOpenDirection)direction
{
    self.drawerWidth = drawerWidth;
    self.openDirection = direction;
    self.drawerView = drawerView;
}

- (void)setDrawerView:(UIView *)drawerView
{
    if (_drawerView)
    {
        [_drawerView removeFromSuperview];
    }
    _drawerView = drawerView;
    _drawerView.alpha = 0;
    
    [self.view addSubview:_drawerView];
    [self.view bringSubviewToFront:self.navigationBar];
    
    [_drawerView addGestureRecognizer:self.panGesure];
    
    [_drawerView mas_makeConstraints:^(MASConstraintMaker *make) {

        make.bottom.equalTo(self.view);
        make.width.equalTo(@(self.drawerWidth));
        
        self.topConstraint = make.top.equalTo(self.view).offset([self _topOffsetFromPinType:self.topPin]);
        
        if (self.openDirection == ANDrawerOpenDirectionFromLeft)
        {
            self.animatedConstraint = make.right.equalTo(self.view.mas_left).offset(0);
        }
        else
        {
            self.animatedConstraint = make.left.equalTo(self.view.mas_right).offset(0);
        }
    }];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    _backgroundColor = backgroundColor;
    self.useBackground = YES;
    self.backgroundView.backgroundColor = backgroundColor;
}

- (CGFloat)_topOffsetFromPinType:(ANDrawerTopPin)pinType
{
    CGFloat topOffset = 0;
    if (pinType == ANDrawerTopPinStatusBar)
    {
        topOffset = kStatusBarHeight;
    }
    else if (pinType == ANDrawerTopPinNavigationBar)
    {
        CGFloat navigationBarHeight = self.navigationBarHidden ? 0 : self.navigationBar.height;
        topOffset = kStatusBarHeight + navigationBarHeight;
    }
    return topOffset;
}

- (void)setTopPin:(ANDrawerTopPin)topPin
{
    _topPin = topPin;
    if (self.topConstraint)
    {
        self.topConstraint.offset([self _topOffsetFromPinType:topPin]);
        [self.view layoutIfNeeded];
    }
}

- (void)setUseBackground:(BOOL)useBackground
{
    _useBackground = useBackground;
    if (_backgroundView && !useBackground)
    {
        [_backgroundView removeFromSuperview];
    }
    [self backgroundColor];
}

- (UIView *)backgroundView
{
    if (!_backgroundView && self.useBackground)
    {
        _backgroundView = [UIView new];
        _backgroundView.hidden = YES;
        [self.view insertSubview:_backgroundView belowSubview:self.drawerView];
        
        [_backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
        
        [_backgroundView addGestureRecognizer:self.panGesure];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
        [[tap.rac_gestureSignal deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
            [self updateStateToOpened:NO];
        }];
        [_backgroundView addGestureRecognizer:tap];
    }
    return _backgroundView;
}

- (UIPanGestureRecognizer *)panGesure
{
    if (!_panGesure)
    {
        _panGesure = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_moveDrawer:)];
    }
    return _panGesure;
}

#pragma mark - Global Opening State

- (void)toggle
{
    [self updateStateToOpened:!self.isOpen];
}

- (void)updateStateToOpened:(BOOL)isOpen
{
    if (isOpen)
    {
        self.backgroundView.hidden = NO;
    }
    if (self.avoidKeyboard)
    {
        [self.view endEditing:YES]; // hack for keyboard;
    }
    
    CGFloat newOffset = isOpen ? [self _offsetForOpenState] : 0;
    
    POPSpringAnimation *leftSideAnimation = [POPSpringAnimation new];
    leftSideAnimation.toValue = @(newOffset);
    leftSideAnimation.property = [POPAnimatableProperty mas_offsetProperty];
    leftSideAnimation.springBounciness = 4;
    [self.animatedConstraint pop_addAnimation:leftSideAnimation forKey:@"offset"];
    
    self.drawerView.spring.alpha = isOpen;
    
    [NSObject animate:^{
        self.backgroundView.spring.alpha = isOpen;
    } completion:^(BOOL finished) {
        if (!isOpen) self.backgroundView.hidden = YES;
    }];
    
    self.isOpen = isOpen;
}

#pragma mark - Private

- (CGFloat)_offsetForOpenState
{
    return (self.openDirection == ANDrawerOpenDirectionFromLeft) ? self.drawerWidth : -self.drawerWidth;
}

- (void)_moveDrawer:(UIPanGestureRecognizer *)recognizer
{
    [self.view endEditing:YES]; // hack for keyboard;
    CGPoint translation = [recognizer translationInView:self.view];
    CGPoint velocity = [recognizer velocityInView:self.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        if (velocity.x > kDefaultDrawerVelocityTrigger && !self.isOpen)
        {
            [self updateStateToOpened:YES];
        }
        else if (velocity.x < -kDefaultDrawerVelocityTrigger && self.isOpen)
        {
            [self updateStateToOpened:NO];
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        CGFloat startOffset = self.isOpen ? [self _offsetForOpenState] : 0;
        CGFloat newOffset = startOffset + translation.x;
        
        if (self.openDirection == ANDrawerOpenDirectionFromLeft)
        {
            newOffset = MAX(0, MIN([self _offsetForOpenState], newOffset));
        }
        else
        {
            newOffset = MIN(0, MAX([self _offsetForOpenState], newOffset));
        }
        
        self.animatedConstraint.offset(newOffset);
        self.backgroundView.hidden = NO;
        self.backgroundView.alpha = 1 / self.drawerWidth * newOffset + 0.5;
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        BOOL newState;
        if (self.openDirection == ANDrawerOpenDirectionFromLeft)
        {
            newState = (self.drawerView.center.x > (self.drawerWidth / 2));
        }
        else
        {
            newState = (self.drawerView.center.x < (self.drawerWidth / 2));
        }
        [self updateStateToOpened:newState];
    }
}

@end

