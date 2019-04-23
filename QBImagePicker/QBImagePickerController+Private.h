//
//  QBImagePickerController+Private.h
//  QBImagePicker
//
//  Created by Dmitry Gruzd on 4/23/19.
//  Copyright © 2019 Dmitry Gruzd. All rights reserved.
//

#import "QBImagePickerController.h"

@interface QBImagePickerController ()

- (PHFetchOptions *)fetchOptionsForAssets;
- (PHFetchOptions *)fetchOptionsForAssetCollections;

@end
