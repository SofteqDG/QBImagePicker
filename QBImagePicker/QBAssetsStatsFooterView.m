//
//  QBAssetsStatsFooterView.m
//  QBImagePicker
//
//  Created by Dmitry Gruzd on 4/25/19.
//  Copyright © 2019 Dmitry Gruzd. All rights reserved.
//

#import "QBAssetsStatsFooterView.h"

@implementation QBAssetsStatsFooterView

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.statsLabel.text = nil;
}

@end
