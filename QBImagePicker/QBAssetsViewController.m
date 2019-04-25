//
//  QBAssetsViewController.m
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import "QBAssetsViewController.h"

// ViewControllers
#import "QBImagePickerController+Private.h"

// Views
#import "QBAssetCell.h"
#import "QBVideoIndicatorView.h"
#import "QBAssetsStatsFooterView.h"

// Model
#import "QBAlbumInfo.h"

static CGSize CGSizeScale(CGSize size, CGFloat scale) {
    return CGSizeMake(size.width * scale, size.height * scale);
}

@implementation NSIndexSet (Convenience)

- (NSArray *)qb_indexPathsFromIndexesWithSection:(NSUInteger)section
{
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:section]];
    }];
    return indexPaths;
}

@end

@implementation UICollectionView (Convenience)

- (NSArray *)qb_indexPathsForElementsInRect:(CGRect)rect
{
    NSArray *allLayoutAttributes = [self.collectionViewLayout layoutAttributesForElementsInRect:rect];
    if (allLayoutAttributes.count == 0) { return nil; }
    
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:allLayoutAttributes.count];
    for (UICollectionViewLayoutAttributes *layoutAttributes in allLayoutAttributes) {
        if (layoutAttributes.representedElementCategory == UICollectionElementCategoryCell) {
            NSIndexPath *indexPath = layoutAttributes.indexPath;
            [indexPaths addObject:indexPath];
        }
    }
    return indexPaths;
}

@end

@interface QBAssetsViewController () <PHPhotoLibraryChangeObserver, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>

@property (nonatomic, strong) IBOutlet UIBarButtonItem *doneButton;

@property (nonatomic, strong) IBOutlet UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) NSIndexPath *lastProcessedCellIndexPath;
@property (nonatomic, assign) BOOL firstProcessedCellWasSelected;

@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property (nonatomic, assign) CGRect previousPreheatRect;

@property (nonatomic, assign) BOOL disableScrollToBottom;
@property (nonatomic, strong) NSIndexPath *lastSelectedItemIndexPath;

@end

@implementation QBAssetsViewController

- (void)dealloc
{
    // Deregister observer
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setUpToolbarItems];
    [self resetCachedAssets];
    
    // Register observer
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Configure navigation item
    self.navigationItem.title = self.albumInfo.assetCollection.localizedTitle;
    self.navigationItem.prompt = self.imagePickerController.prompt;
    
    // Configure collection view
    self.collectionView.allowsMultipleSelection = self.imagePickerController.allowsMultipleSelection;
    
    // Show/hide 'Done' button
    if (self.imagePickerController.allowsMultipleSelection) {
        [self.navigationItem setRightBarButtonItem:self.doneButton animated:NO];
    } else {
        [self.navigationItem setRightBarButtonItem:nil animated:NO];
    }
    
    [self updateDoneButtonState];
    if (self.imagePickerController.showsNumberOfSelectedAssets) {
        [self updateSelectionInfo];
        [self updateToolbar];
    }
    
    [self.collectionView reloadData];
    
    // Scroll to bottom
    PHFetchResult *fetchResult = self.albumInfo.assetsFetchResult;
    if (fetchResult.count > 0 && self.isMovingToParentViewController && !self.disableScrollToBottom) {
        __weak typeof(self) weakSelf = self;
        [self.collectionView performBatchUpdates:^{} completion:^(BOOL finished) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:(fetchResult.count - 1) inSection:0];
            [weakSelf.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.disableScrollToBottom = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.disableScrollToBottom = NO;
    
    [self updateCachedAssets];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    // Save indexPath for the last item
    NSIndexPath *indexPath = [[self.collectionView indexPathsForVisibleItems] lastObject];
    
    // Update layout
    [self.collectionViewLayout invalidateLayout];
    
    // Restore scroll position
    __weak typeof(self) weakSelf = self;
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [weakSelf.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
    }];
}

#pragma mark - Accessors

- (void)setAlbumInfo:(QBAlbumInfo *)albumInfo {
    _albumInfo = [albumInfo copy];
    if (albumInfo.assetCollection) {
        if ([self isAutoDeselectEnabled] && self.imagePickerController.selectedAssets.count > 0) {
            // Get index of previous selected asset
            PHAsset *asset = [self.imagePickerController.selectedAssets firstObject];
            NSInteger assetIndex = [albumInfo.assetsFetchResult indexOfObject:asset];
            self.lastSelectedItemIndexPath = [NSIndexPath indexPathForItem:assetIndex inSection:0];
        }
    }
    [self.collectionView reloadData];
}

- (PHCachingImageManager *)imageManager
{
    if (_imageManager == nil) {
        _imageManager = [[PHCachingImageManager alloc] init];
    }
    
    return _imageManager;
}

- (BOOL)isAutoDeselectEnabled
{
    return (self.imagePickerController.maximumNumberOfSelection == 1
            && self.imagePickerController.maximumNumberOfSelection >= self.imagePickerController.minimumNumberOfSelection);
}


#pragma mark - Actions

- (IBAction)done:(id)sender
{
    NSArray *assets = self.imagePickerController.selectedAssets.array;
    [self.imagePickerController.delegate qb_imagePickerController:self.imagePickerController didFinishPickingAssets:assets];
}


#pragma mark - Toolbar

- (void)setUpToolbarItems
{
    // Space
    UIBarButtonItem *leftSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    UIBarButtonItem *rightSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    
    // Info label
    NSDictionary *attributes = @{ NSForegroundColorAttributeName: [UIColor blackColor] };
    UIBarButtonItem *infoButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:NULL];
    infoButtonItem.enabled = NO;
    [infoButtonItem setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [infoButtonItem setTitleTextAttributes:attributes forState:UIControlStateDisabled];
    
    self.toolbarItems = @[leftSpace, infoButtonItem, rightSpace];
}

- (void)updateSelectionInfo
{
    NSMutableOrderedSet *selectedAssets = self.imagePickerController.selectedAssets;
    
    if (selectedAssets.count > 0) {
        NSBundle *bundle = [NSBundle bundleForClass:[QBAssetsViewController class]];
        NSString *format;
        if (selectedAssets.count > 1) {
            format = NSLocalizedStringFromTableInBundle(@"assets.toolbar.items-selected", @"QBImagePicker", bundle, nil);
        } else {
            format = NSLocalizedStringFromTableInBundle(@"assets.toolbar.item-selected", @"QBImagePicker", bundle, nil);
        }
        
        NSString *title = [NSString stringWithFormat:format, selectedAssets.count];
        [(UIBarButtonItem *)self.toolbarItems[1] setTitle:title];
    } else {
        [(UIBarButtonItem *)self.toolbarItems[1] setTitle:@""];
    }
}

- (void)updateToolbar {
    BOOL hidden = (self.imagePickerController.selectedAssets.count < 1);
    if (self.navigationController.toolbarHidden != hidden) {
        [self.navigationController setToolbarHidden:hidden animated:YES];
    }
}

#pragma mark - Checking for Selection Limit

- (BOOL)isMinimumSelectionLimitFulfilled
{
   return (self.imagePickerController.minimumNumberOfSelection <= self.imagePickerController.selectedAssets.count);
}

- (BOOL)isMaximumSelectionLimitReached
{
    NSUInteger minimumNumberOfSelection = MAX(1, self.imagePickerController.minimumNumberOfSelection);
   
    if (minimumNumberOfSelection <= self.imagePickerController.maximumNumberOfSelection) {
        return (self.imagePickerController.maximumNumberOfSelection <= self.imagePickerController.selectedAssets.count);
    }
   
    return NO;
}

- (void)updateDoneButtonState
{
    self.doneButton.enabled = [self isMinimumSelectionLimitFulfilled];
}


#pragma mark - Asset Caching

- (void)resetCachedAssets
{
    [self.imageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets
{
    BOOL isViewVisible = [self isViewLoaded] && self.view.window != nil;
    if (!isViewVisible) {
        return;
    }
    
    // The preheat window is twice the height of the visible rect
    CGRect preheatRect = self.collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, 0.0, -0.5 * CGRectGetHeight(preheatRect));
    
    // If scrolled by a "reasonable" amount...
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    
    if (delta > CGRectGetHeight(self.collectionView.bounds) / 3.0) {
        // Compute the assets to start caching and to stop caching
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect addedHandler:^(CGRect addedRect) {
            NSArray *indexPaths = [self.collectionView qb_indexPathsForElementsInRect:addedRect];
            [addedIndexPaths addObjectsFromArray:indexPaths];
        } removedHandler:^(CGRect removedRect) {
            NSArray *indexPaths = [self.collectionView qb_indexPathsForElementsInRect:removedRect];
            [removedIndexPaths addObjectsFromArray:indexPaths];
        }];
        
        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
        
        CGSize itemSize = [self collectionView:self.collectionView layout:self.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        CGSize targetSize = CGSizeScale(itemSize, [[UIScreen mainScreen] scale]);
        
        [self.imageManager startCachingImagesForAssets:assetsToStartCaching
                                            targetSize:targetSize
                                           contentMode:PHImageContentModeAspectFill
                                               options:nil];
        [self.imageManager stopCachingImagesForAssets:assetsToStopCaching
                                           targetSize:targetSize
                                          contentMode:PHImageContentModeAspectFill
                                              options:nil];
        
        self.previousPreheatRect = preheatRect;
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect addedHandler:(void (^)(CGRect addedRect))addedHandler removedHandler:(void (^)(CGRect removedRect))removedHandler
{
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths
{
    if (indexPaths.count == 0) {
        return nil;
    }
    
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        if (indexPath.item < self.albumInfo.assetsFetchResult.count) {
            PHAsset *asset = self.albumInfo.assetsFetchResult[indexPath.item];
            [assets addObject:asset];
        }
    }
    return assets;
}

- (BOOL)shouldSelectAssetAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.imagePickerController.delegate respondsToSelector:@selector(qb_imagePickerController:shouldSelectAsset:)]) {
        PHAsset *asset = self.albumInfo.assetsFetchResult[indexPath.item];
        return [self.imagePickerController.delegate qb_imagePickerController:self.imagePickerController shouldSelectAsset:asset];
    }
    
    if ([self isAutoDeselectEnabled]) {
        return YES;
    }
    
    return ![self isMaximumSelectionLimitReached];
}


#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:strongSelf.albumInfo.assetsFetchResult];
        if (collectionChanges) {
            // Get the new fetch result
            strongSelf.albumInfo.assetsFetchResult = [collectionChanges fetchResultAfterChanges];
            if (![collectionChanges hasIncrementalChanges] || [collectionChanges hasMoves]) {
                // We need to reload all if the incremental diffs are not available
                [strongSelf.collectionView reloadData];
            } else {
                // If we have incremental diffs, tell the collection view to animate insertions and deletions
                [strongSelf.collectionView performBatchUpdates:^{
                    NSIndexSet *removedIndexes = [collectionChanges removedIndexes];
                    if ([removedIndexes count]) {
                        [strongSelf.collectionView deleteItemsAtIndexPaths:[removedIndexes qb_indexPathsFromIndexesWithSection:0]];
                    }
                    
                    NSIndexSet *insertedIndexes = [collectionChanges insertedIndexes];
                    if ([insertedIndexes count]) {
                        [strongSelf.collectionView insertItemsAtIndexPaths:[insertedIndexes qb_indexPathsFromIndexesWithSection:0]];
                    }
                    
                    NSIndexSet *changedIndexes = [collectionChanges changedIndexes];
                    if ([changedIndexes count]) {
                        NSMutableIndexSet *changedWithoutRemovalsIndexes = [changedIndexes mutableCopy];
                        [changedWithoutRemovalsIndexes removeIndexes:removedIndexes];
                        [self.collectionView reloadItemsAtIndexPaths:[changedWithoutRemovalsIndexes qb_indexPathsFromIndexesWithSection:0]];
                    }
                    
                    [collectionChanges enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
                        NSIndexPath *toIndexPath = [NSIndexPath indexPathForItem:toIndex inSection:0];
                        NSIndexPath *fromIndexPath = [NSIndexPath indexPathForItem:fromIndex inSection:0];
                        [strongSelf.collectionView moveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
                    }];
                } completion:NULL];
                
                NSArray *visibleFooterViews = [strongSelf.collectionView visibleSupplementaryViewsOfKind:UICollectionElementKindSectionFooter];
                for (QBAssetsStatsFooterView *footerView in visibleFooterViews) {
                    [strongSelf configureAssetsStatsFooterView:footerView];
                }
            }
            
            [strongSelf resetCachedAssets];
        }
    });
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateCachedAssets];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.albumInfo.assetsFetchResult.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    QBAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AssetCell" forIndexPath:indexPath];
    cell.tag = indexPath.item;
    cell.showsOverlayViewWhenSelected = self.imagePickerController.allowsMultipleSelection;
    
    // Image
    PHAsset *asset = self.albumInfo.assetsFetchResult[indexPath.item];
    UICollectionViewLayoutAttributes *layoutAttributes = [collectionView layoutAttributesForItemAtIndexPath:indexPath];
    CGSize targetSize = CGSizeScale(layoutAttributes.size, [[UIScreen mainScreen] scale]);
    
    [self.imageManager requestImageForAsset:asset
                                 targetSize:targetSize
                                contentMode:PHImageContentModeAspectFill
                                    options:nil
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  if (result != nil && cell.tag == indexPath.item) {
                                      cell.imageView.image = result;
                                  }
                              }];
    
    // Video indicator
    if (asset.mediaType == PHAssetMediaTypeVideo) {
        cell.videoIndicatorView.hidden = NO;
        
        NSInteger minutes = (NSInteger)(asset.duration / 60.0);
        NSInteger seconds = (NSInteger)ceil(asset.duration - 60.0 * (double)minutes);
        cell.videoIndicatorView.timeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
        
        if (asset.mediaSubtypes & PHAssetMediaSubtypeVideoHighFrameRate) {
            cell.videoIndicatorView.videoIcon.hidden = YES;
            cell.videoIndicatorView.slomoIcon.hidden = NO;
        }
        else {
            cell.videoIndicatorView.videoIcon.hidden = NO;
            cell.videoIndicatorView.slomoIcon.hidden = YES;
        }
    } else {
        cell.videoIndicatorView.hidden = YES;
    }
    
    // Selection state
    if ([self.imagePickerController.selectedAssets containsObject:asset]) {
        [cell setSelected:YES];
        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (kind == UICollectionElementKindSectionFooter) {
        QBAssetsStatsFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                                                 withReuseIdentifier:@"FooterView"
                                                                                        forIndexPath:indexPath];
        
        [self configureAssetsStatsFooterView:footerView];
        return footerView;
    }
    
    // Just to silence the static analyzer.
    return [[UICollectionReusableView alloc] init];
}

- (void)configureAssetsStatsFooterView:(QBAssetsStatsFooterView *)footerView {
    NSBundle *bundle = [NSBundle bundleForClass:[QBAssetsViewController class]];
    NSUInteger numberOfPhotos = [self.albumInfo.assetsFetchResult countOfAssetsWithMediaType:PHAssetMediaTypeImage];
    NSUInteger numberOfVideos = [self.albumInfo.assetsFetchResult countOfAssetsWithMediaType:PHAssetMediaTypeVideo];
    
    BOOL filterContainsImageMediaType = NO;
    BOOL filterContainsVideoMediaType = NO;
    for (NSNumber *mediaType in self.imagePickerController.assetMediaTypes) {
        switch (mediaType.integerValue) {
            case PHAssetMediaTypeImage: {
                filterContainsImageMediaType = YES;
                break;
            }
            case PHAssetMediaTypeVideo: {
                filterContainsVideoMediaType = YES;
                break;
            }
            default: {
                break;
            }
        }
    }
    
    UILabel *label = footerView.statsLabel;
    if (filterContainsImageMediaType && !filterContainsVideoMediaType) {
        // Only images
        NSString *key = (numberOfPhotos == 1) ? @"assets.footer.photo" : @"assets.footer.photos";
        NSString *format = NSLocalizedStringFromTableInBundle(key, @"QBImagePicker", bundle, nil);
        label.text = [NSString stringWithFormat:format, numberOfPhotos];
    } else if (!filterContainsImageMediaType && filterContainsVideoMediaType) {
        // Only videos
        NSString *key = (numberOfVideos == 1) ? @"assets.footer.video" : @"assets.footer.videos";
        NSString *format = NSLocalizedStringFromTableInBundle(key, @"QBImagePicker", bundle, nil);
        label.text = [NSString stringWithFormat:format, numberOfVideos];
    } else {
        // Both images and videos
        NSString *format;
        if (numberOfPhotos == 1) {
            if (numberOfVideos == 1) {
                format = NSLocalizedStringFromTableInBundle(@"assets.footer.photo-and-video", @"QBImagePicker", bundle, nil);
            } else {
                format = NSLocalizedStringFromTableInBundle(@"assets.footer.photo-and-videos", @"QBImagePicker", bundle, nil);
            }
        } else if (numberOfVideos == 1) {
            format = NSLocalizedStringFromTableInBundle(@"assets.footer.photos-and-video", @"QBImagePicker", bundle, nil);
        } else {
            format = NSLocalizedStringFromTableInBundle(@"assets.footer.photos-and-videos", @"QBImagePicker", bundle, nil);
        }
        label.text = [NSString stringWithFormat:format, numberOfPhotos, numberOfVideos];
    }
}

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self shouldSelectAssetAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    QBImagePickerController *imagePickerController = self.imagePickerController;
    NSMutableOrderedSet *selectedAssets = imagePickerController.selectedAssets;
    PHAsset *asset = self.albumInfo.assetsFetchResult[indexPath.item];
    
    if (imagePickerController.allowsMultipleSelection) {
        if ([self isAutoDeselectEnabled] && selectedAssets.count > 0) {
            // Remove previous selected asset from set
            [selectedAssets removeObjectAtIndex:0];
            
            // Deselect previous selected asset
            if (self.lastSelectedItemIndexPath) {
                [collectionView deselectItemAtIndexPath:self.lastSelectedItemIndexPath animated:NO];
            }
        }
        
        // Add asset to set
        [selectedAssets addObject:asset];
        
        self.lastSelectedItemIndexPath = indexPath;
        
        [self updateDoneButtonState];
        
        if (imagePickerController.showsNumberOfSelectedAssets) {
            [self updateSelectionInfo];
            [self updateToolbar];
        }
    } else {
        [imagePickerController.delegate qb_imagePickerController:imagePickerController didFinishPickingAssets:@[asset]];
        // TODO: Should we return here?
    }
    
    if ([imagePickerController.delegate respondsToSelector:@selector(qb_imagePickerController:didSelectAsset:)]) {
        [imagePickerController.delegate qb_imagePickerController:imagePickerController didSelectAsset:asset];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.imagePickerController.allowsMultipleSelection) {
        return;
    }
    
    QBImagePickerController *imagePickerController = self.imagePickerController;
    NSMutableOrderedSet *selectedAssets = imagePickerController.selectedAssets;
    PHAsset *asset = self.albumInfo.assetsFetchResult[indexPath.item];
    
    // Remove asset from set
    [selectedAssets removeObject:asset];
    
    self.lastSelectedItemIndexPath = nil;
    
    [self updateDoneButtonState];
    
    if (imagePickerController.showsNumberOfSelectedAssets) {
        [self updateSelectionInfo];
        [self updateToolbar];
    }
    
    if ([imagePickerController.delegate respondsToSelector:@selector(qb_imagePickerController:didDeselectAsset:)]) {
        [imagePickerController.delegate qb_imagePickerController:imagePickerController didDeselectAsset:asset];
    }
}


#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger numberOfColumns = self.imagePickerController.numberOfColumnsInPortrait;
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        numberOfColumns = self.imagePickerController.numberOfColumnsInLandscape;
    }
    
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)collectionViewLayout;
    UIEdgeInsets sectionInsets = flowLayout.sectionInset;
    
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = collectionView.safeAreaInsets;
    }
    
    CGFloat contentWidth = CGRectGetMaxX(collectionView.frame);
    contentWidth -= (safeAreaInsets.left + safeAreaInsets.right);
    contentWidth -= (sectionInsets.left + sectionInsets.right);
    
    CGFloat spacingWidth = flowLayout.minimumInteritemSpacing * (numberOfColumns - 1);
    CGFloat itemWidth = MAX(1.0, (contentWidth - spacingWidth) / numberOfColumns);
    
    return CGSizeMake(itemWidth, itemWidth);
}


#pragma mark - UILongPressGestureRecognizer Action

- (IBAction)longPressGestureRecognizerAction:(UIGestureRecognizer *)sender
{
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            if (self.lastProcessedCellIndexPath) {
                return;
            }
            
            self.collectionView.userInteractionEnabled = NO;
            self.collectionView.scrollEnabled = NO;
            self.lastProcessedCellIndexPath = nil;
        }
        case UIGestureRecognizerStateChanged: {
            CGPoint pointOnCollectionView = [sender locationInView:self.collectionView];
            NSIndexPath *cellIndexPath = [self.collectionView indexPathForItemAtPoint:pointOnCollectionView];
            if (!cellIndexPath || cellIndexPath == self.lastProcessedCellIndexPath) {
                return;
            }
            
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:cellIndexPath];
            if (!self.lastProcessedCellIndexPath) {
                self.firstProcessedCellWasSelected = !cell.selected;
            }
            self.lastProcessedCellIndexPath = cellIndexPath;
            
            switch (self.imagePickerController.gesturesSelectionStyle) {
                case QBImagePickerGesturesSelectionStyleUseFirstStateChange: {
                    if (self.firstProcessedCellWasSelected && [self shouldSelectAssetAtIndexPath:cellIndexPath] && !cell.selected) {
                        [self.collectionView selectItemAtIndexPath:cellIndexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
                        [self collectionView:self.collectionView didSelectItemAtIndexPath:cellIndexPath];
                    } else if (!self.firstProcessedCellWasSelected && cell.selected) {
                        [self.collectionView deselectItemAtIndexPath:cellIndexPath animated:YES];
                        [self collectionView:self.collectionView didDeselectItemAtIndexPath:cellIndexPath];
                    }
                    [self.collectionView scrollToItemAtIndexPath:cellIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
                    break;
                }
                default: {
                    if (cell.selected) {
                        [self.collectionView deselectItemAtIndexPath:cellIndexPath animated:YES];
                        [self collectionView:self.collectionView didDeselectItemAtIndexPath:cellIndexPath];
                    } else if ([self shouldSelectAssetAtIndexPath:cellIndexPath]) {
                        [self.collectionView selectItemAtIndexPath:cellIndexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
                        [self collectionView:self.collectionView didSelectItemAtIndexPath:cellIndexPath];
                    }
                    [self.collectionView scrollToItemAtIndexPath:cellIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
                    break;
                }
            }
            break;
        }
        default: {
            if (!self.lastProcessedCellIndexPath) {
                return;
            }
            
            self.collectionView.userInteractionEnabled = YES;
            self.collectionView.scrollEnabled = YES;
            self.lastProcessedCellIndexPath = nil;
            break;
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    QBImagePickerController *imagePickerController = self.imagePickerController;
    if (!imagePickerController.allowsMultipleSelection || !imagePickerController.allowsMultipleSelectionWithGestures) {
        return NO;
    }
    
    CGPoint pointOnCollectionView = [gestureRecognizer locationInView:self.collectionView];
    NSIndexPath *cellIndexPath = [self.collectionView indexPathForItemAtPoint:pointOnCollectionView];
    if (!cellIndexPath) {
        return NO;
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}

@end
