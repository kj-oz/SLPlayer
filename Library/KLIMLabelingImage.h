//
//  KLIMLabelingImage.h
//  KLib Image
//
//  Created by KO on 13/10/14.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KLIMBinaryImage;

/**
 * 2値化画像の連続する1(前景)画素群をラベリング（番号付け）てして管理するクラス.
 */
@interface KLIMLabelingImage : NSObject

// 各画素毎のラベルを保持する配列
@property (nonatomic, assign) UInt32 *pixels;

// 画像の幅
@property (nonatomic, assign) NSInteger width;

// 画像の高さ
@property (nonatomic, assign) NSInteger height;

// 各画素群の配列
@property (nonatomic, readonly) NSMutableArray *blocks;

/**
 * 2値化画像をラベリングする.
 * @param image 2値化画像
 * @return ラベリング結果
 */
- (id)initWithBinaryImage:(KLIMBinaryImage *)image;

/**
 * ラベリング結果を画像として取得する.
 * @return 各画素群毎に色を変えた画像
 */
- (UIImage *)createImage;

/**
 * ラベリング結果から指定の番号の画素群のみを抽出した画像を取得する.
 * @param labels 出力する番号の配列
 * @return 各画素群毎に色を変えた画像
 */
- (UIImage *)createImageWithFilter:(NSIndexSet *)labels;

@end
