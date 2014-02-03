//
//  KLIMNumberDetecter.h
//  KLib Image
//
//  Created by KO on 13/10/22.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KLIMBinaryImage;
@class KLIMLabelingBlock;

/**
 * 画素群から数字を認識するクラス.
 */
@interface KLIMNumberDetecter : NSObject

/**
 * 与えられたパラメータで、数字認識器を生成する.
 * @param width 画素群の境界上に線が引かれているかどうかを判定する幅(画素数)
 */
- (id)initWithBorderCheckWidth:(NSInteger)width;

/**
 * 与えられた画素群がから数字を認識する.
 * @param block 画素群
 * @param bin 画素群の元データを保持する2値化画像
 * @return 数字、認識に失敗した場合-1が返る
 */
- (NSInteger)detectWithBlock:(KLIMLabelingBlock *)block ofImage:(KLIMBinaryImage *)bin;

@end
