//
//  QBImagePickerController.h
//  QBImagePicker
//
//  Created by Katsuma Tanaka on 2015/04/03.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

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

typedef NS_ENUM(NSUInteger, QBImagePickerMediaType) {
    QBImagePickerMediaTypeAny = 0,
    QBImagePickerMediaTypeImage,
    QBImagePickerMediaTypeVideo
};

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

@property (nonatomic, weak, readwrite) id<QBImagePickerControllerDelegate> delegate;
@property (nonatomic, strong, readonly) NSMutableOrderedSet *selectedAssets;

@property (nonatomic, copy) NSArray *assetCollectionSubtypes;
@property (nonatomic, assign) QBImagePickerMediaType mediaType;
@property (nonatomic, assign) QBImagePickerCreationDateSortOrder creationDateSortOrder;

@property (nonatomic, assign) BOOL allowsMultipleSelection;
@property (nonatomic, assign) BOOL allowsMultipleSelectionWithGestures;
@property (nonatomic, assign) QBImagePickerGesturesSelectionStyle gesturesSelectionStyle;

@property (nonatomic, assign) NSUInteger minimumNumberOfSelection;
@property (nonatomic, assign) NSUInteger maximumNumberOfSelection;

@property (nonatomic, copy) NSString *prompt;
@property (nonatomic, assign) BOOL showsNumberOfSelectedAssets;

@property (nonatomic, assign) NSUInteger numberOfColumnsInPortrait;
@property (nonatomic, assign) NSUInteger numberOfColumnsInLandscape;

@end
