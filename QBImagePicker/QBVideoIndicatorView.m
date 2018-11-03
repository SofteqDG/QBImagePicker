//
//  QBVideoIndicatorView.m
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/04.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import "QBVideoIndicatorView.h"

@implementation QBVideoIndicatorView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.gradientView.gradientLayer.colors = @[
                                               (__bridge id)[[UIColor clearColor] CGColor],
                                               (__bridge id)[[UIColor blackColor] CGColor]
                                               ];
}

@end
