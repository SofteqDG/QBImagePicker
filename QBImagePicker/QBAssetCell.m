//
//  QBAssetCell.m
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import "QBAssetCell.h"
#import "QBVideoIndicatorView.h"

@interface QBAssetCell ()

@property (nonatomic, weak) IBOutlet UIView *overlayView;

@end

@implementation QBAssetCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.imageView.image = nil;
    self.videoIndicatorView.timeLabel.text = nil;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    // Show/hide overlay view
    self.overlayView.hidden = !(selected && self.showsOverlayViewWhenSelected);
}

@end
