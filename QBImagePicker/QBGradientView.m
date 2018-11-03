//
//  QBGradientView.h
//  QBImagePicker
//
//  Created by Dmitry Gruzd on 2018/11/03.
//  Copyright (c) 2018 Dmitry Gruzd. All rights reserved.
//

#import "QBGradientView.h"

@implementation QBGradientView
@dynamic gradientLayer;

+ (Class)layerClass
{
    return CAGradientLayer.class;
}

- (CAGradientLayer *)gradientLayer
{
    return (CAGradientLayer *)self.layer;
}

@end
