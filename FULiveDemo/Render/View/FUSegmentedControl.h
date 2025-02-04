//
//  FUSegmentedControl.h
//  FULiveDemo
//
//  Created by 项林平 on 2022/10/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FUSegmentedControl : UIView

@property (nonatomic, strong, nullable) NSArray<NSString *> *items;

@property (nonatomic, strong) UIColor *titleColor;

@property (nonatomic, strong) UIColor *selectedTitleColor;

@property (nonatomic, strong) UIFont *titleFont;

@property (nonatomic, assign) NSUInteger selectedIndex;

@property (nonatomic, copy) void (^selectHandler)(NSUInteger index);

- (instancetype)initWithFrame:(CGRect)frame items:(nullable NSArray<NSString *> *)items;

@end

@interface FUSegmentedCell : UICollectionViewCell

@property (nonatomic, strong, readonly) UILabel *textLabel;

@property (nonatomic, strong) UIColor *textColor;

@property (nonatomic, strong) UIColor *selectedTextColor;

@end

NS_ASSUME_NONNULL_END
