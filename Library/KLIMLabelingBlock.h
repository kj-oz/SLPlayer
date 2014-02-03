//
//  KLIMLabelingBlock.h
//  KLib Image
//
//  Created by KO on 13/10/14.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 2値化画像の連続する1(前景)画素群を表すクラス.
 */
@interface KLIMLabelingBlock : NSObject

// ラベル（番号）
@property (nonatomic, readonly) NSInteger label;

// 画素数
@property (nonatomic, readonly) NSInteger area;

// X方向最小座標
@property (nonatomic, readonly) NSInteger xmin;

// Y方向最小座標
@property (nonatomic, readonly) NSInteger ymin;

// X方向最大座標
@property (nonatomic, readonly) NSInteger xmax;

// Y方向最大座標
@property (nonatomic, readonly) NSInteger ymax;

// (外接長方形の)幅
@property (nonatomic, readonly) NSInteger width;

// (外接長方形の)高さ
@property (nonatomic, readonly) NSInteger height;

// 重心の座標
@property (nonatomic, readonly) CGPoint center;

// 各種処理で自由に使用可能な作業用プロパティ
@property (nonatomic, assign) NSInteger work;

// 穴の数
@property (nonatomic, assign) NSInteger numHole;

/**
 * 指定の番号の空の画素群を準備する.
 * @param label 番号
 * @return 空の画素群
 */
- (id)initWithLabel:(NSInteger)label;

/**
 * 指定の位置の画素を加える.
 * @param x X座標
 * @param y Y座標
 */
- (void)addPixelWithX:(NSInteger)x andY:(NSInteger)y;

@end
