//
//  KLIMNumberDetecter.m
//  KLib Image
//
//  Created by KO on 13/10/22.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import "KLIMNumberDetecter.h"
#import "KLIMLabelingBlock.h"
#import "KLIMBinaryImage.h"

@implementation KLIMNumberDetecter
{
    // 画素群の境界上に線が引かれているかどうかを判定する幅(画素数)
    NSInteger _borderCheckWidth;
    
    // 画素群
    KLIMLabelingBlock *_block;
    
    // 元画像
    KLIMBinaryImage *_bin;
}

#pragma mark - 初期化

- (id)initWithBorderCheckWidth:(NSInteger)width
{
    self = [super init];
    if (self) {
        _borderCheckWidth = width;
    }
    return self;
}

#pragma mark - 処理

- (NSInteger)detectWithBlock:(KLIMLabelingBlock *)block ofImage:(KLIMBinaryImage *)bin
{
    _block = block;
    _bin = bin;
    
    switch (_block.numHole) {
        case 2:
            // 穴が2つあれば8
            printf("8\n");
            return 8;
        case 1:
            // 穴が1つ
            if ([self topDensity] < 0.2) {
                // 上辺の密度が0.2以下なら4
                printf("4\n");
                return 4;
            }
            CGFloat lDensity = [self leftDensity];
            CGFloat rDensity = [self rightDensity];
            // 左右辺の密度を比較し
            if (lDensity < rDensity * 0.8) {
                // 左辺が右辺の8割以下なら9
                printf("9\n");
                return 9;
            } else if (rDensity < lDensity * 0.8) {
                // 右辺が左辺の8割以下なら6
                printf("6\n");
                return 6;
            } else {
                // ほぼ均等なら0
                printf("0\n");
                return 0;
            }
        case 0: {
            // 穴なし
            if ([self aspectRatio] < 0.6) {
                // 縦横比が0.6以下なら1
                printf("1\n");
                return 1;
            }
            NSInteger ans;
            CGFloat bDensity = [self bottomDensity];
//            CGFloat tDensity = [self topDensity];
//            CGFloat lDensity = [self leftDensity];
//            CGFloat rDensity = [self rightDensity];
            CGFloat rlDensity = [self rightLHDensity];
            //　底辺の密度を調べて
            if (bDensity > 0.8) {
                // 0.95以上あれば2
                ans = 2;
            } else if ([self topDensity] > 0.8) {
                // 上辺が0.95以上なら
                // 底辺が0.2より大きければ5、それ以下なら7
                ans = bDensity > 0.2 ? 5 : 7;
            } else if (bDensity < 0.65) {
                ans = 3;
            } else if ([self rightLHDensity] < 0.35) {
                // 右辺下半分が0.4以下なら2
                // 下辺が0.95以下のケースもあるため
                ans = 2;
            } else {
                // 残りは3
                ans = 3;
            }
            printf("%ld,%.2f,%.2f\n", (long)ans, bDensity, rlDensity);
            return ans;
        }
        default:
            // 認識に失敗
            return -1;
    }
}

#pragma mark - プライベートメソッド

/**
 * 画素群の縦横比を得る.
 * @return 縦横比
 */
- (CGFloat)aspectRatio
{
    return (CGFloat)_block.width / _block.height;
}

/**
 * 底辺の線の割合を得る.
 * @return 底辺の線の割合
 */
- (CGFloat)bottomDensity
{
    return [self horizontalDensityFromY0:(_block.ymax - _borderCheckWidth + 1) toY1:_block.ymax];
}

/**
 * 上辺の線の割合を得る.
 * @return 上辺の線の割合
 */
- (CGFloat)topDensity
{
    return [self horizontalDensityFromY0:_block.ymin toY1:(_block.ymin + _borderCheckWidth - 1)];
}

/**
 * 中央の水平線の割合を得る.
 * @return 中央の水平線の割合
 */
- (CGFloat)centerHDensity
{
    NSInteger center = (_block.ymax + _block.ymin) / 2;
    NSInteger y0 = center - _borderCheckWidth / 2;
    NSInteger y1 = y0 + _borderCheckWidth / 2 - 1;
    return [self horizontalDensityFromY0:y0 toY1:y1];
}
                       
/**
 * 与えられた上限から下限の間の水平方向の線の割合を得る.
 * @param y0 上限
 * @param y1 下限
 * @return 水平方向の線の割合
 */
- (CGFloat)horizontalDensityFromY0:(NSInteger)y0 toY1:(NSInteger)y1
{
    NSInteger count = 0;
    for (NSInteger x = _block.xmin; x <= _block.xmax; x++) {
        for (NSInteger y = y0; y <= y1; y++) {
            if (_bin.buffer[y * _bin.width + x]) {
                count++;
                break;
            }
        }
    }
    return (CGFloat)count / _block.width;
}

/**
 * 左辺の線の割合を得る.
 * @return 左辺の線の割合
 */
- (CGFloat)leftDensity
{
    return [self verticalDensityFromX0:_block.xmin toX1:(_block.xmin + _borderCheckWidth - 1)
                                  atY0:_block.ymin toY1:_block.ymax];
}

/**
 * 右辺の線の割合を得る.
 * @return 右辺の線の割合
 */
- (CGFloat)rightDensity
{
    return [self verticalDensityFromX0:(_block.xmax - _borderCheckWidth + 1) toX1:_block.xmax
                                  atY0:_block.ymin toY1:_block.ymax];
}

/**
 * 右辺下半分の線の割合を得る.
 * @return 右辺下半分の線の割合
 */
- (CGFloat)rightLHDensity
{
    NSInteger h0 = (_block.ymax + _block.ymin) / 2;
    return [self verticalDensityFromX0:(_block.xmax - _borderCheckWidth + 1) toX1:_block.xmax
                                  atY0:h0 toY1:_block.ymax];
}

/**
 * 与えられた左端から右端の間の鉛直方向の線の割合を得る.
 * @param x0 左端
 * @param x1 右端
 * @return 鉛直方向の線の割合
 */
- (CGFloat)verticalDensityFromX0:(NSInteger)x0 toX1:(NSInteger)x1 atY0:(NSInteger)y0 toY1:(NSInteger)y1
{
    NSInteger count = 0;
    for (NSInteger y = y0; y <= y1; y++) {
        for (NSInteger x = x0; x <= x1; x++) {
            if (_bin.buffer[y * _bin.width + x]) {
                count++;
                break;
            }
        }
    }
    return (CGFloat)count / (y1 - y0 + 1);
}

@end
