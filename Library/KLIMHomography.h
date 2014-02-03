//
//  KLIMHomography.h
//  KLib Image
//
//  Created by KO on 13/10/18.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 画像の中の4点で囲まれた内部を長方形の画像として抽出する射影変換を行うクラス.
 */
@interface KLIMHomography : NSObject

/**
 * 与えられた画像の与えられた領域から指定のサイズの長方形の画像を抽出する.
 * @param points 元画像の領域を表す4点の座標、左上、右上、右下、左下の順で指定する.
 * @param image 元画像
 * @param size 出力される画像のサイズ
 * @return 出力画像
 */
- (UIImage *)transformFromPoints:(CGPoint *)points ofImage:(UIImage *)image toSize:(CGSize)size;

@end
