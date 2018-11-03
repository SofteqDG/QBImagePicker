//
//  QBSlomoIconView.m
//  QBImagePicker
//
//  Created by Julien Chaumond on 22/04/2015.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import "QBSlomoIconView.h"

@implementation QBSlomoIconView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupDefaults];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupDefaults];
    }
    return self;
}

- (void)setupDefaults
{
    self.iconColor = [UIColor whiteColor];
}

#pragma mark - Properties

- (void)setIconColor:(UIColor *)iconColor
{
    _iconColor = iconColor;
    [self setNeedsDisplay];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    [self.iconColor setStroke];
    
    CGFloat width = 2.2;
    CGRect insetRect = CGRectInset(rect, width / 2, width / 2);
    
    // Draw dashed circle
    UIBezierPath* circlePath = [UIBezierPath bezierPathWithOvalInRect:insetRect];
    circlePath.lineWidth = width;
    CGFloat ovalPattern[] = {0.75, 0.75};
    [circlePath setLineDash:ovalPattern count:2 phase:0];
    [circlePath stroke];
}

@end
