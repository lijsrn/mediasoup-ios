//
//  ViewController.m
//  webrtc_mediasoup
//
//  Created by JH on 2020/4/25.
//  Copyright © 2020 JH. All rights reserved.
//

#import "ViewController.h"
#import "VieoRoomPresenter.h"

#import "RendererData.h"
#import "MediaViewCell.h"
#import "RendererData.h"

@interface ViewController ()<UICollectionViewDelegate,UICollectionViewDataSource>

@property(nonatomic,strong) UICollectionView *collectionView;

@property (nonatomic, strong) VieoRoomPresenter *presenter;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    UICollectionViewFlowLayout *layOut = [[UICollectionViewFlowLayout alloc] init];

    CGFloat w = self.view.frame.size.width / 2 - 1;
    layOut.itemSize = CGSizeMake(w, w / 0.75);

    layOut.sectionInset = UIEdgeInsetsMake(0, 0, 1, 0);

    layOut.minimumLineSpacing = 1;

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) collectionViewLayout:layOut];

    _collectionView.pagingEnabled = YES;

    _collectionView.backgroundColor = [UIColor clearColor];

    [_collectionView registerClass:[MediaViewCell class] forCellWithReuseIdentifier:@"MediaViewCell"];

    _collectionView.semanticContentAttribute = UISemanticContentAttributeSpatial;

    _collectionView.delegate = self;

    _collectionView.dataSource = self;

    [self.view addSubview:_collectionView];

    _presenter = [[VieoRoomPresenter alloc] initWithView:_collectionView];
    [_presenter connectWebSocket];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 1.0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _presenter.mediaDatas.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    MediaViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MediaViewCell" forIndexPath:indexPath];

    RendererData *data = _presenter.mediaDatas[indexPath.row];

    [cell addMediaView:(UIView *)data.videoView];

    return cell;
}


@end
