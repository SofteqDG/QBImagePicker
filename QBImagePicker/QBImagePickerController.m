//
//  QBImagePickerController.m
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import <Photos/Photos.h>

#import "QBImagePickerController.h"

// ViewControllers
#import "QBAlbumsViewController.h"

@interface QBImagePickerController ()

@property (nonatomic, strong, readwrite) NSMutableOrderedSet *selectedAssets;
@property (nonatomic, weak, readwrite) QBAlbumsViewController *albumsViewController;
@property (nonatomic, weak, readwrite) UINavigationController *albumsNavigationController;

@end

@implementation QBImagePickerController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupDefaults];
        [self setupAlbumsViewController];
    }
    return self;
}

- (void)setupDefaults
{
    self.minimumNumberOfSelection = 1;
    self.maximumNumberOfSelection = 0;
    self.numberOfColumnsInPortrait = 4;
    self.numberOfColumnsInLandscape = 7;
    self.creationDateSortOrder = QBImagePickerCreationDateSortOrderAscending;
    
    self.allowsMultipleSelection = YES;
    self.allowsMultipleSelectionWithGestures = YES;
    self.gesturesSelectionStyle = QBImagePickerGesturesSelectionStyleAlwaysChangeState;
    
    self.selectedAssets = [NSMutableOrderedSet orderedSet];
    self.assetCollectionSubtypes = @[@(PHAssetCollectionSubtypeSmartAlbumUserLibrary),
                                     @(PHAssetCollectionSubtypeAlbumMyPhotoStream),
                                     @(PHAssetCollectionSubtypeSmartAlbumPanoramas),
                                     @(PHAssetCollectionSubtypeSmartAlbumVideos),
                                     @(PHAssetCollectionSubtypeSmartAlbumBursts)];
}

- (void)setupAlbumsViewController
{
    NSBundle *bundle = [NSBundle bundleForClass:[QBImagePickerController class]];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"QBImagePicker" bundle:bundle];
    
    UINavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:@"QBAlbumsNavigationController"];
    self.albumsNavigationController = navigationController;
    
    [self addChildViewController:navigationController];
    navigationController.view.frame = self.view.bounds;
    navigationController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:navigationController.view];
    [navigationController didMoveToParentViewController:self];
    
    self.albumsViewController = (QBAlbumsViewController *)self.albumsNavigationController.topViewController;
    self.albumsViewController.imagePickerController = self;
}

@end
