//
//  FUImageRenderViewController.m
//  FULiveDemo
//
//  Created by 项林平 on 2022/8/8.
//

#import "FUImageRenderViewController.h"

#import "FULandmarkManager.h"

@interface FUImageRenderViewController ()

@property (nonatomic, strong) FUGLDisplayView *renderView;

@property (nonatomic, strong) UIButton *downloadButton;

@property (nonatomic, strong) UILabel *noTrackLabel;

@property (nonatomic, strong) UILabel *tipLabel;

@property (nonatomic, strong) FUImageRenderViewModel *viewModel;

@end

@implementation FUImageRenderViewController

#pragma mark - Initializer

- (instancetype)initWithViewModel:(FUImageRenderViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        self.viewModel.delegate = self;
    }
    return self;
}

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureUI];
    
    [self.viewModel start];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 添加点位测试开关
    if ([FURenderKitManager sharedManager].showsLandmarks) {
        [FULandmarkManager show];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 移除点位测试开关
    if ([FURenderKitManager sharedManager].showsLandmarks) {
        [FULandmarkManager dismiss];
    }
}

- (void)dealloc {
    [self.viewModel stop];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - UI

- (void)configureUI {
    self.view.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:self.renderView];
    [self.renderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
            if(FUDeviceIsiPhoneXStyle()) {
                make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).mas_offset(-50);
            } else {
                make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
            }
        } else {
            make.top.equalTo(self.view.mas_top);
            make.bottom.equalTo(self.view.mas_bottom);
        }
        make.leading.trailing.equalTo(self.view);
    }];
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:[UIImage imageNamed:@"back_item"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
    [backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(20);
        } else {
            make.top.equalTo(self.view.mas_top).offset(30);
        }
        make.leading.equalTo(self.view.mas_leading).offset(10);
        make.size.mas_offset(CGSizeMake(44, 44));
    }];
    
    
    [self.view addSubview:self.noTrackLabel];
    [self.noTrackLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
    
    [self.view addSubview:self.tipLabel];
    [self.tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.view.mas_centerY).mas_offset(24);
        make.centerX.equalTo(self.view);
        make.width.mas_equalTo(300);
        make.height.mas_equalTo(32);
    }];
    
    [self.view addSubview:self.downloadButton];
    [self.downloadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom).offset(-self.viewModel.downloadButtonBottomConstant - 10);
        make.centerX.equalTo(self.view);
        make.size.mas_offset(CGSizeMake(85, 85));
    }];
}

#pragma mark - Instance methods

- (void)updateBottomConstraintsOfDownloadButton:(CGFloat)constraints {
    [self.downloadButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom).mas_offset(-constraints-10);
    }];
    [UIView animateWithDuration:0.15 animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - Event response

- (void)backAction:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)downloadAction:(UIButton *)sender {
    @FUWeakify(self)
    self.viewModel.captureImageHandler = ^(UIImage * _Nonnull image) {
        @FUStrongify(self)
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
        });
    };
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        [FUTipHUD showTips:FULocalizedString(@"保存图片失败") dismissWithDelay:1.5];
    } else {
        [FUTipHUD showTips:FULocalizedString(@"图片已保存到相册") dismissWithDelay:1.5];
    }
}

- (void)applicationWillResignActive {
    [self.viewModel stop];
}

- (void)applicationDidBecomeActive {
    [self.viewModel start];
}

#pragma mark - FUImageRenderViewModelDelegate

- (void)imageRenderDidOutputImageBuffer:(FUImageBuffer)imageBuffer {
    [self.renderView displayImageData:imageBuffer.buffer0 withSize:imageBuffer.size];
}

- (void)imageRenderShouldCheckDetectingStatus:(FUDetectingParts)parts {
    @autoreleasepool {
        BOOL detectingResult = YES;
        switch (parts) {
            case FUDetectingPartsFace:
                detectingResult = [FURenderKitManager faceTracked];
                break;
            case FUDetectingPartsHuman:
                detectingResult = [FURenderKitManager humanTracked];
                break;
            case FUDetectingPartsHand:
                detectingResult = [FURenderKitManager handTracked];
                break;
            default:
                break;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.noTrackLabel.hidden = detectingResult;
            if (!detectingResult) {
                self.noTrackLabel.text = parts == FUDetectingPartsFace ? FULocalizedString(@"未检测到人脸") : (parts == FUDetectingPartsHuman ? FULocalizedString(@"未检测到人体") : FULocalizedString(@"未检测到手势"));
            }
        });
    }
}

#pragma mark - Getters

- (UIButton *)downloadButton {
    if (!_downloadButton) {
        _downloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _downloadButton.frame = CGRectMake(CGRectGetWidth(self.view.bounds) / 2.0 - 42.5, CGRectGetHeight(self.view.bounds) - 85 - FUHeightIncludeBottomSafeArea(10), 85, 85);
        _downloadButton.backgroundColor = [UIColor whiteColor];
        _downloadButton.layer.cornerRadius = 42.5;
        [_downloadButton setBackgroundImage:[UIImage imageNamed:@"render_save"] forState:UIControlStateNormal];
        [_downloadButton addTarget:self action:@selector(downloadAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _downloadButton;
}

- (UILabel *)noTrackLabel {
    if (!_noTrackLabel) {
        _noTrackLabel = [[UILabel alloc] init];
        _noTrackLabel.textColor = [UIColor whiteColor];
        _noTrackLabel.font = [UIFont systemFontOfSize:17];
        _noTrackLabel.text = FULocalizedString(@"未检测到人脸");
        _noTrackLabel.hidden = YES;
    }
    return _noTrackLabel;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.textColor = [UIColor whiteColor];
        _tipLabel.font = [UIFont systemFontOfSize:32];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.hidden = YES;
    }
    return _tipLabel;
}

- (FUGLDisplayView *)renderView {
    if (!_renderView) {
        _renderView = [[FUGLDisplayView alloc] initWithFrame:self.view.bounds];
        _renderView.contentMode = FUGLDisplayViewContentModeScaleAspectFit;
    }
    return _renderView;
}

#pragma mark - Override methods

- (BOOL)prefersStatusBarHidden {
    return !FUDeviceIsiPhoneXStyle();
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
