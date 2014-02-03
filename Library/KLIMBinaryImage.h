//
//  KLIMBinaryImage.h
//  KLib Image
//
//  Created by KO on 13/10/13.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 2値化画像を取り扱うクラス.
 * 2値化画像の背景は0、前景は1となる
 */
@interface KLIMBinaryImage : NSObject

@property (nonatomic, assign) UInt8 *buffer;
@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;

/**
 * 与えられたカラー画像を固定閾値で2値化する.
 * @param image 元画像
 * @param threshold 閾値、明度を0(黒)から1(白)の間の値で指定する
 * @return 2値化画像インスタンス
 */
- (id)initWithUIImage:(UIImage *)image threshold:(CGFloat)threshold;

/**
 * 与えられたカラー画像を適応的閾値を用いて2値化する.
 * @param image 元画像
 * @return 2値化画像インスタンス
 */
- (id)initWithUIImage:(UIImage *)image;

/**
 * 与えられた2値化画像を複製する.
 * @param image 元画像
 * @return 新たな2値化画像インスタンス
 */
- (id)initWithBinaryImage:(KLIMBinaryImage *)image;

/**
 * 2値化画像の膨張処理を行う.
 */
- (void)expand;

/**
 * 2値化画像の収縮処理を行う.
 */
- (void)contract;

/**
 * 画像の外周の幅1ピクセル分を背景(0)化する
 */
- (void)ensureClearEdge;

/**
 * 1ピクセルだけ単独で周辺と異なる値のピクセルを周辺と同じ値にする.
 */
- (void)removeCrumb;

/**
 * 白黒の画像を得る.
 * @return 背景が白、前景が黒のカラー画像
 */
- (UIImage *)createImage;

@end
