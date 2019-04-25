//
//  QBAlbumInfo.m
//  QBImagePicker
//
//  Created by Dmitry Gruzd on 4/25/19.
//  Copyright © 2019 Dmitry Gruzd. All rights reserved.
//

#import "QBAlbumInfo.h"

@implementation QBAlbumInfo

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    QBAlbumInfo *copiedAlbumInfo = [[QBAlbumInfo alloc] init];
    copiedAlbumInfo.assetCollection = [_assetCollection copyWithZone:zone];
    copiedAlbumInfo.assetsFetchOptions = [_assetCollection copyWithZone:zone];
    copiedAlbumInfo.assetsFetchResult = [_assetsFetchResult copyWithZone:zone];
    return copiedAlbumInfo;
}

#pragma mark - Properties

- (PHFetchResult *)assetsFetchResult {
    if (!_assetsFetchResult) {
        _assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:self.assetCollection options:self.assetsFetchOptions];
    }
    return _assetsFetchResult;
}

@end
