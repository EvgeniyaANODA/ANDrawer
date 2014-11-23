//
//  ANDrawerNC.m
//
//  Created by Oksana Kovalchuk on 6/17/14.
//  Copyright (c) 2014 ANODA. All rights reserved.
//

#import "ANDrawerNC.h"
#import "MSSPopMasonry.h"
#define MCANIMATE_SHORTHAND
#import <POP+MCAnimate.h>

static CGFloat const kDefaultDrawerVelocityTrigger = 350;

static CGFloat CDCalculateStatusBarHeight() {
    return (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) ?
    [[UIApplication sharedApplication] statusBarFrame].size.width :
    [[UIApplication sharedApplication] statusBarFrame].size.height;
}

@interface ANDrawerNC () <UIGestureRecognizerDelegate>

@property (nonatomic, assign) BOOL isOpen;
@property (nonatomic, strong) UIView *shawdowView;
@property (nonatomic, strong) MASConstraint* leftSideConstraint;

@property (nonatomic, strong) UIView *drawerView;
@property (nonatomic, assign) CGFloat drawerWidth;

@end

@implementation ANDrawerNC

- (void)updateDrawerView:(UIView *)drawerView width:(CGFloat)drawerWidth
{
    self.drawerWidth = drawerWidth;
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
    
    [self.view bringSubviewToFront:self.shawdowView];
    [self.view addSubview:_drawerView];
    [self.view bringSubviewToFront:self.navigationBar];
    
    [_drawerView mas_makeConstraints:^(MASConstraintMaker *make) {

        make.top.bottom.equalTo(self.view);
        make.top.offset(CDCalculateStatusBarHeight());
        make.width.equalTo(@(self.drawerWidth));
        self.leftSideConstraint = make.left.equalTo(self.view.mas_right).offset(0);
    }];
}

- (UIView *)shawdowView
{
    if (!_shawdowView)
    {
        _shawdowView = [UIView new];
        _shawdowView.hidden = YES;
        [self.view addSubview:_shawdowView];
        
        [_shawdowView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
    }
    return _shawdowView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UITapGestureRecognizer *tapIt = [[UITapGestureRecognizer alloc] init];
    [[tapIt.rac_gestureSignal deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
        [self updateDrawerStateToOpened:NO];
    }];
    
    UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveDrawer:)];
    [self.drawerView addGestureRecognizer:pan];
    
    [self.shawdowView addGestureRecognizer:tapIt];
    [self.shawdowView addGestureRecognizer:pan];
}

- (void)toggle
{
    [self updateDrawerStateToOpened:!self.isOpen];
}

#pragma mark - open and close action

- (void)updateDrawerStateToOpened:(BOOL)isOpen
{
    if (isOpen)
    {
        self.shawdowView.hidden = NO;
        [self.view endEditing:YES]; // hack for keyboard;
    }
    
    CGFloat newOffset = isOpen ? -self.drawerWidth : 0;
    POPSpringAnimation *leftSideAnimation = [POPSpringAnimation new];
    leftSideAnimation.toValue = @(newOffset);
    leftSideAnimation.property = [POPAnimatableProperty mas_offsetProperty];
    leftSideAnimation.springBounciness = 4;
    [self.leftSideConstraint pop_addAnimation:leftSideAnimation forKey:@"offset"];
    
    self.drawerView.spring.alpha = isOpen;
    
    [NSObject animate:^{
        self.shawdowView.alpha = isOpen;
    } completion:^(BOOL finished) {
        if (!isOpen) self.shawdowView.hidden = YES;
    }];
    
    self.isOpen = isOpen;
}

#pragma mark - gestures

- (void)moveDrawer:(UIPanGestureRecognizer *)recognizer
{
    [self.view endEditing:YES]; // hack for keyboard;
    CGPoint translation = [recognizer translationInView:self.view];
    CGPoint velocity = [recognizer velocityInView:self.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        if (velocity.x > kDefaultDrawerVelocityTrigger && !self.isOpen)
        {
            [self updateDrawerStateToOpened:YES];
        }
        else if (velocity.x < -kDefaultDrawerVelocityTrigger && self.isOpen)
        {
            [self updateDrawerStateToOpened:NO];
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        CGFloat startOffset = self.isOpen ? -self.drawerWidth : 0;
        CGFloat newOffset = startOffset + translation.x;
        
        newOffset = MIN(0, MAX(-self.drawerWidth, newOffset));
        self.leftSideConstraint.offset(newOffset);
        self.shawdowView.hidden = NO;
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        BOOL newState = (self.drawerView.center.x < self.view.width);
        [self updateDrawerStateToOpened:newState];
    }
}

@end

