//
//  QBAlbumInfo.h
//  QBImagePicker
//
//  Created by Dmitry Gruzd on 4/25/19.
//  Copyright © 2019 Dmitry Gruzd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface QBAlbumInfo : NSObject <NSCopying>

@property (nonatomic, strong) PHAssetCollection *assetCollection;
@property (nonatomic, strong) PHFetchOptions *assetsFetchOptions;
@property (nonatomic, strong) PHFetchResult *assetsFetchResult;

@end
