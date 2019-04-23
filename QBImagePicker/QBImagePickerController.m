//
//  QBImagePickerController.m
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import "QBImagePickerController+Private.h"

// ViewControllers
#import "QBAlbumsViewController.h"

@interface QBImagePickerController ()

@property (nonatomic, strong, readwrite) PHFetchOptions *assetsFetchOptions;
@property (nonatomic, strong, readwrite) PHFetchOptions *assetCollectionsFetchOptions;

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
    self.selectedAssets = [NSMutableOrderedSet orderedSet];
    
    self.minimumNumberOfSelection = 1;
    self.maximumNumberOfSelection = 0;
    self.numberOfColumnsInPortrait = 4;
    self.numberOfColumnsInLandscape = 7;
    
    self.mediaType = QBImagePickerMediaTypeAny;
    self.creationDateSortOrder = QBImagePickerCreationDateSortOrderAscending;
    self.excludeEmptyCollections = NO;
    
    self.allowsMultipleSelection = YES;
    self.allowsMultipleSelectionWithGestures = YES;
    self.gesturesSelectionStyle = QBImagePickerGesturesSelectionStyleAlwaysChangeState;
    
    self.assetMediaSubtypes = nil;
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

#pragma mark - Properties

- (PHFetchOptions *)assetsFetchOptions {
    if (!_assetsFetchOptions) {
        NSMutableArray *sortDescriptors = [NSMutableArray array];
        NSMutableArray *predicates = [NSMutableArray array];
        
        switch (self.creationDateSortOrder) {
            case QBImagePickerCreationDateSortOrderAscending: {
                NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES];
                [sortDescriptors addObject:sortDescriptor];
                break;
            }
                
            case QBImagePickerCreationDateSortOrderDescending: {
                NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO];
                [sortDescriptors addObject:sortDescriptor];
                break;
            }
                
            default: {
                break;
            }
        }
        
        switch (self.mediaType) {
            case QBImagePickerMediaTypeImage: {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
                [predicates addObject:predicate];
                break;
            }
                
            case QBImagePickerMediaTypeVideo: {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
                [predicates addObject:predicate];
                break;
            }
                
            default: {
                break;
            }
        }
        
        if (self.assetMediaSubtypes.count) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mediaSubtype in %@ ", self.assetMediaSubtypes];
            [predicates addObject:predicate];
        }
        
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = (sortDescriptors.count ? sortDescriptors : nil);
        options.predicate = (predicates.count ? [NSCompoundPredicate andPredicateWithSubpredicates:predicates] : nil);
        _assetsFetchOptions = options;
    }
    return _assetsFetchOptions;
}

- (PHFetchOptions *)assetCollectionsFetchOptions {
    return nil;
}

- (void)setAssetCollectionSubtypes:(NSArray *)assetCollectionSubtypes {
    _assetCollectionSubtypes = [assetCollectionSubtypes copy];
    self.assetCollectionsFetchOptions = nil;
    self.assetsFetchOptions = nil;
}

- (void)setMediaType:(QBImagePickerMediaType)mediaType {
    _mediaType = mediaType;
    self.assetCollectionsFetchOptions = nil;
    self.assetsFetchOptions = nil;
}

- (void)setCreationDateSortOrder:(QBImagePickerCreationDateSortOrder)creationDateSortOrder {
    _creationDateSortOrder = creationDateSortOrder;
    self.assetCollectionsFetchOptions = nil;
    self.assetsFetchOptions = nil;
}

#pragma mark - Private

- (PHFetchOptions *)fetchOptionsForAssets {
    return self.assetsFetchOptions;
}

- (PHFetchOptions *)fetchOptionsForAssetCollections {
    return self.assetCollectionsFetchOptions;
}

@end
