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

@property (nonatomic, strong, readwrite, nullable) PHFetchOptions *assetsFetchOptions;
@property (nonatomic, strong, readwrite, nullable) PHFetchOptions *assetCollectionsFetchOptions;

@property (nonatomic, strong, readwrite) NSMutableOrderedSet<PHAsset *> *selectedAssets;
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
    
    self.creationDateSortOrder = QBImagePickerCreationDateSortOrderAscending;
    self.excludeEmptyCollections = NO;
    
    self.allowsMultipleSelection = YES;
    self.allowsMultipleSelectionWithGestures = YES;
    self.gesturesSelectionStyle = QBImagePickerGesturesSelectionStyleAlwaysChangeState;
    
    self.assetMediaTypes = nil;
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
        
        if (self.assetMediaTypes.count) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mediaType IN %@", self.assetMediaTypes];
            [predicates addObject:predicate];
        }
        
        if (self.assetMediaSubtypes.count) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mediaSubtype IN %@ ", self.assetMediaSubtypes];
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

- (void)setAssetMediaTypes:(NSArray<NSNumber *> *)assetMediaTypes {
    _assetMediaTypes = [assetMediaTypes copy];
    self.assetCollectionsFetchOptions = nil;
    self.assetsFetchOptions = nil;
}

- (void)setAssetMediaSubtypes:(NSArray<NSNumber *> *)assetMediaSubtypes {
    _assetMediaSubtypes = [assetMediaSubtypes copy];
    self.assetCollectionsFetchOptions = nil;
    self.assetsFetchOptions = nil;
}

- (void)setAssetCollectionSubtypes:(NSArray<NSNumber *> *)assetCollectionSubtypes {
    _assetCollectionSubtypes = [assetCollectionSubtypes copy];
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

@implementation QBImagePickerController (Deprecated)
@dynamic mediaType;

- (QBImagePickerMediaType)mediaType {
    return QBImagePickerMediaTypeAny;
}

- (void)setMediaType:(QBImagePickerMediaType)mediaType {
    
}

@end
