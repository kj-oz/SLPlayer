//
//  KLIMGridDetector.h
//  KLib Image
//
//  Created by KO on 13/10/16.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KLIMBinaryImage;
@class KLIMLabelingBlock;

/**
 * 画像から抽出したグリッド(一定の間隔で四角に並べられている点群)を表すクラス.
 */
@interface KLIMPointGrid : NSObject

// 列数（水平方向の点の数 - 1）
@property (nonatomic, readonly) NSInteger numCol;

// 行数（垂直方向の点の数 - 1）
@property (nonatomic, readonly) NSInteger numRow;

// 中央と認識した点が水平方向の何番目の点か（一番左が0）
@property (nonatomic, readonly) NSInteger axesX;

// 中央と認識した点が垂直方向の何番目の点か（一番上が0）
@property (nonatomic, readonly) NSInteger axesY;

// 点同士の間隔
@property (nonatomic, readonly) NSInteger pitch;


/**
 * 与えられた画像からグリッドを抽出する.
 * @param image 2値化画像、グリッドが最低限画像の中心付近を覆っている必要がある
 * @return 画像から抽出されたグリッド、認識に失敗した場合、nilが返る.
 */
- (id)initWithBinaryImage:(KLIMBinaryImage *)image;


/**
 * グリッドの指定の位置の制御点の画素群を得る.
 * @param pos 位置（0:左上、1:中上、2:右上、3:左中、4:中央、5:右中、6:左下、7:中下、8:右下）
 *　　　　　　　　ここで中というのは、グリッドの丁度中央ではなく元画像中央付近の適当な点を指す
 * @return 点の画素群
 */
- (KLIMLabelingBlock *)ctrlBlockOfPosition:(NSInteger)pos;

/**
 * 制御点のみの画像を得る.
 * @return 制御点のみの画像、制御点の色はランダムに設定される.
 */
- (UIImage *)createImageOfCtrlPoint;

@end

