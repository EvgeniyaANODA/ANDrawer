//
//  ANDrawerNC.h
//
//  Created by Oksana Kovalchuk on 6/17/14.
//  Copyright (c) 2014 ANODA. All rights reserved.
//

@interface ANDrawerNC : UINavigationController

- (void)updateDrawerView:(UIView*)drawerView width:(CGFloat)drawerWidth;

- (void)toggle;

@end
