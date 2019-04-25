//
//  QBImagePickerController.h
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@class QBImagePickerController;

@protocol QBImagePickerControllerDelegate <NSObject>

@required
- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets;
- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController;

@optional
- (BOOL)qb_imagePickerController:(QBImagePickerController *)imagePickerController shouldSelectAsset:(PHAsset *)asset;
- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didSelectAsset:(PHAsset *)asset;
- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didDeselectAsset:(PHAsset *)asset;

@end

typedef NS_ENUM(NSUInteger, QBImagePickerCreationDateSortOrder) {
    QBImagePickerCreationDateSortOrderNone = 0,
    QBImagePickerCreationDateSortOrderAscending,
    QBImagePickerCreationDateSortOrderDescending
};

typedef NS_ENUM(NSUInteger, QBImagePickerGesturesSelectionStyle) {
    QBImagePickerGesturesSelectionStyleAlwaysChangeState = 0,
    QBImagePickerGesturesSelectionStyleUseFirstStateChange
};

@interface QBImagePickerController : UIViewController

@property (nonatomic, weak, readwrite, nullable) id<QBImagePickerControllerDelegate> delegate;
@property (nonatomic, strong, readonly, nonnull) NSMutableOrderedSet<PHAsset *> *selectedAssets;

@property (nonatomic, copy, readwrite, nullable) NSArray<NSNumber *> *assetMediaTypes;
@property (nonatomic, copy, readwrite, nullable) NSArray<NSNumber *> *assetMediaSubtypes;
@property (nonatomic, copy, readwrite, nullable) NSArray<NSNumber *> *assetCollectionSubtypes;

@property (nonatomic, assign) BOOL excludeEmptyCollections;
@property (nonatomic, assign) QBImagePickerCreationDateSortOrder creationDateSortOrder;

@property (nonatomic, assign) BOOL allowsMultipleSelection;
@property (nonatomic, assign) BOOL allowsMultipleSelectionWithGestures;
@property (nonatomic, assign) QBImagePickerGesturesSelectionStyle gesturesSelectionStyle;

@property (nonatomic, assign) NSUInteger minimumNumberOfSelection;
@property (nonatomic, assign) NSUInteger maximumNumberOfSelection;

@property (nonatomic, copy, nullable) NSString *prompt;
@property (nonatomic, assign) BOOL showsNumberOfSelectedAssets;

@property (nonatomic, assign) NSUInteger numberOfColumnsInPortrait;
@property (nonatomic, assign) NSUInteger numberOfColumnsInLandscape;

@end

@interface QBImagePickerController (Deprecated)

typedef NS_ENUM(NSUInteger, QBImagePickerMediaType) {
    QBImagePickerMediaTypeAny = 0,
    QBImagePickerMediaTypeImage,
    QBImagePickerMediaTypeVideo
} DEPRECATED_MSG_ATTRIBUTE("Use 'assetMediaTypes' property");

@property (nonatomic, assign) QBImagePickerMediaType mediaType DEPRECATED_MSG_ATTRIBUTE("Use 'assetMediaTypes' property");

@end

NS_ASSUME_NONNULL_END
