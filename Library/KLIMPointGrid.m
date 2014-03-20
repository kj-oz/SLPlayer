//
//  KLIMGridDetector.m
//  KLib Image
//
//  Created by KO on 13/10/16.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import "KLIMPointGrid.h"
#import "KLCGPointUtil.h"
#import "KLIMBinaryImage.h"
#import "KLIMLabelingImage.h"
#import "KLIMLabelingBlock.h"

#pragma mark - KLIMAxesBlock

/**
 * グリッドの軸の両端に位置する画素群.
 */
@interface KLIMAxesBlock : NSObject

// 中央点までの距離（スパン数）
@property (nonatomic, assign) NSInteger distance;

// 画素群
@property (nonatomic, weak) KLIMLabelingBlock *block;

@end

@implementation KLIMAxesBlock
@end


#pragma mark - KLIMGridDetector

@implementation KLIMPointGrid
{
    // 2値化画像
    KLIMBinaryImage *_bin;
    
    // ラベリング画像
    KLIMLabelingImage *_li;
    
    // ラベリングされた画素群
    NSMutableArray *_blocks;
    
    // 点の検索半径
    CGFloat _searchDistance;
    
    // 制御点の画素群
    __weak KLIMLabelingBlock *_ctrlBlocks[9];
    
    // 中央と認識した点から左端・右端までのスパン数
    NSInteger _nx[2];
    
    // 中央と認識した点から上端・下端までのスパン数
    NSInteger _ny[2];
}

#pragma mark - 初期化

- (id)initWithBinaryImage:(KLIMBinaryImage *)image
{
    self = [super init];
    if (self) {
        _bin = image;
        _li = [[KLIMLabelingImage alloc] initWithBinaryImage:image];
        _blocks = [NSMutableArray array];
        
        // 以下の判定基準は、1000X1000程度のイメージを想定
        for (NSInteger i = 1; i < _li.blocks.count; i++) {
            KLIMLabelingBlock *block = _li.blocks[i];
            if (1 < block.width && block.width < 14 &&
                1 < block.height && block.height < 14 &&
                4 < block.area && block.area < 120) {
                [_blocks addObject:block];
            }
        }
        
        // 中心に近い16ブロックから検証
        // 点の検索半径はイメージ幅の1/10（10×10の問題でも最低１つの点は見つかる距離を想定）とする
        _searchDistance = image.width / 10;
        NSArray *centerBlocks = [self sortByDistanceFromPoint:
                CGPointMake(image.width/2, image.height/2) maxCount:16 maxDistance:_searchDistance];
        for (NSInteger c = 0; c < centerBlocks.count; c++) {
            KLIMLabelingBlock *centerBlock = centerBlocks[c];
            if ([self generateGridWithCenter:centerBlock]) {
                break;
            }
        }
        if (_nx[0] == 0) {
            return nil;
        }
    }
    return self;
}

#pragma mark - プロパティ

- (KLIMLabelingBlock *)ctrlBlockOfPosition:(NSInteger)pos
{
    return _ctrlBlocks[pos];
}

- (NSInteger)numCol
{
    return _nx[0] + _nx[1];
}

- (NSInteger)numRow
{
    return _ny[0] + _ny[1];
}

- (NSInteger)axesX
{
    return _nx[0];
}

- (NSInteger)axesY
{
    return _ny[0];
}

- (NSInteger)pitch
{
    CGFloat dist = KLCGPointDistance(_ctrlBlocks[5].center, _ctrlBlocks[3].center);
    return (NSInteger)ceilf(dist / self.numCol);
}

#pragma mark - 出力

- (UIImage *)createImageOfCtrlPoint
{
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (NSInteger i = 0; i < 9; i++) {
        KLIMLabelingBlock *block = _ctrlBlocks[i];
        [indexes addIndex:block.label];
    }
    return [_li createImageWithFilter:indexes];
}

#pragma mark - プライベートメソッド群

/**
 * 与えられた画素群を中央点としてグリッドの認識を試みる.
 * @param centerBlock 中央点と見なす画素群
 * @return グリッド認識に成功したかどうか
 */
- (BOOL)generateGridWithCenter:(KLIMLabelingBlock *)centerBlock
{
    CGPoint cp = centerBlock.center;
    
    // 対象ブロックに最も近い4ブロックを得る
    // その4点が2方向の軸の起点になるはず
    NSArray *nearBlockes = [self sortByDistanceFromPoint:centerBlock.center
                                                maxCount:5 maxDistance:_searchDistance];
    nearBlockes = [self sortByPosition:[nearBlockes subarrayWithRange:NSMakeRange(1, 4)]];
    
    CGPoint xminP = ((KLIMLabelingBlock *)nearBlockes[0]).center;
    CGPoint xmaxP = ((KLIMLabelingBlock *)nearBlockes[2]).center;
    CGPoint yminP = ((KLIMLabelingBlock *)nearBlockes[1]).center;
    CGPoint ymaxP = ((KLIMLabelingBlock *)nearBlockes[3]).center;
    if (![self isCenter:cp ofPoint:xminP andPoint:xmaxP] ||
            ![self isCenter:cp ofPoint:yminP andPoint:ymaxP]) {
        return NO;        
    }
    
    // X軸の仮確定
    KLIMAxesBlock *xa0 = [self getAxesOfBasePoint:xminP center:cp maxLength:cp.x];
    KLIMAxesBlock *xa1 = [self getAxesOfBasePoint:xmaxP center:cp maxLength:(_bin.width - cp.x)];
    if (!xa0 || !xa1) {
        return NO;        
    }
    // Y軸の仮確定
    KLIMAxesBlock *ya0 = [self getAxesOfBasePoint:yminP center:cp maxLength:cp.y];
    KLIMAxesBlock *ya1 = [self getAxesOfBasePoint:ymaxP center:cp maxLength:(_bin.height - cp.y)];
    if (!ya0 || !ya1) {
        return NO;
    }
    
    KLIMLabelingBlock *c00 = nil;
    KLIMLabelingBlock *c10 = nil;
    KLIMLabelingBlock *c01 = nil;
    KLIMLabelingBlock *c11 = nil;
    
    // 各コーナーの確定
    while (YES) {
        if (!c00) { // 左上
            c00 = [self getCornerWithXEnd:xa0 yEnd:ya0 center:cp];
        }
        if (!c10) { // 右上
            c10 = [self getCornerWithXEnd:xa1 yEnd:ya0 center:cp];
        }
        if (!c01) { // 左下
            c01 = [self getCornerWithXEnd:xa0 yEnd:ya1 center:cp];
        }
        if (!c11) { // 右下
            c11 = [self getCornerWithXEnd:xa1 yEnd:ya1 center:cp];
        }
        
        if (!c00) {
            if (!c01) {
                xa0 = [self getNextAxesOf:xa0 center:cp];
                if (!xa0) {
                    return NO;
                }
                continue;
            } else {
                ya0 = [self getNextAxesOf:ya0 center:cp];
                if (!ya0) {
                    return NO;
                }
                c10 = nil;
                continue;
            }
        }
        
        if (!c10) {
            if (!c11) {
                xa1 = [self getNextAxesOf:xa1 center:cp];
                if (!xa1) {
                    return NO;
                }
                continue;
            } else {
                ya0 = [self getNextAxesOf:ya0 center:cp];
                if (!ya0) {
                    return NO;
                }
                c00 = nil;
                continue;
            }
        }
        
        if (!c01) {
            ya1 = [self getNextAxesOf:ya1 center:cp];
            if (!ya1) {
                return NO;
            }
            c11 = nil;
            continue;
        }
        
        if (!c11) {
            ya1 = [self getNextAxesOf:ya1 center:cp];
            if (!ya0) {
                return NO;
            }
            c01 = nil;
            continue;
        }
        break;
    }

    // 中央
    _ctrlBlocks[4] = centerBlock;
    
    // 左中央
    _ctrlBlocks[3] = xa0.block;
    _nx[0] = xa0.distance;
    // 右中央
    _ctrlBlocks[5] = xa1.block;
    _nx[1] = xa1.distance;
    
    // 上中央
    _ctrlBlocks[1] = ya0.block;
    _ny[0] = ya0.distance;
    // 下中央
    _ctrlBlocks[7] = ya1.block;
    _ny[1] = ya1.distance;
    
    // 左上
    _ctrlBlocks[0] = c00;
    // 右上
    _ctrlBlocks[2] = c10;
    // 左下
    _ctrlBlocks[6] = c01;
    // 右下
    _ctrlBlocks[8] = c11;

    return YES;
}

/**
 * 与えられた点が与えられた始点、終点の中心に位置するかどうかを調べる.
 * @param center 点の座標
 * @param sp 始点の座標
 * @param ep 終点の座標
 * @return 与えられた点が与えられた始点、終点の中心に位置するかどうか
 */
- (BOOL)isCenter:(CGPoint)center ofPoint:(CGPoint)sp andPoint:(CGPoint)ep
{
    CGPoint cp = KLCGPointMiddle(sp, ep);
    // 中点からの距離が、始終点間の距離の7%以内（経験則）か
    return KLCGPointDistance2(cp, center) < KLCGPointDistance2(sp, ep) * 0.005;
}

/**
 * 与えられた中央の点とその次の点を元に、延長上の端点を見つけ出す.
 * @param bp 中央近傍の軸の起点の座標
 * @param center 中央の座標
 * @param length 端点を探す最大の距離
 * @return 与えられた起点の延長上の端点の画素群とその距離
 */
- (KLIMAxesBlock *)getAxesOfBasePoint:(CGPoint)bp center:(CGPoint)center maxLength:(CGFloat)length
{
    CGPoint bvec = KLCGPointSubtract(bp, center);
    CGFloat pitch = KLCGPointLength(bvec);
    
    NSInteger imax = length / pitch;
    for (NSInteger i = imax; i > 3; i--) {
        CGPoint pt = KLCGPointAdd(center, KLCGPointMultiply(bvec, i));
        
        NSArray *blocks = [self sortByDistanceFromPoint:pt
                                               maxCount:4 maxDistance:_searchDistance];
        for (NSInteger b = 0; b < blocks.count; b++) {
            KLIMLabelingBlock *block = blocks[b];
            // 中央点と起点の座標を元に推定される点と実際の点の距離の差が長さの3%以内（経験則）か
            CGFloat dmax = i * pitch * 0.03;
            if (KLCGPointDistance2(block.center, pt) < dmax * dmax) {
                if ([self isOnGridWithPoint:block.center onNthGrid:i fromCenter:center]) {
                    KLIMAxesBlock *axes = [[KLIMAxesBlock alloc] init];
                    axes.distance = i;
                    axes.block = block;
                    return axes;
                }
            }
        }
    }
    return nil;
}

/**
 * 与えられた軸端点より１つ内側の端点を見つけ出す.
 * @param org 元の軸端点
 * @param center 中央の座標
 * @return 元の軸端点の１つ内側の軸端点
 */
- (KLIMAxesBlock *)getNextAxesOf:(KLIMAxesBlock *)org center:(CGPoint)center
{
    CGPoint op = org.block.center;
    CGPoint avec = KLCGPointDevide(KLCGPointSubtract(op, center), org.distance);
    CGPoint pt = KLCGPointSubtract(op, avec);
    // ここまでの認識が正しければほぼ正しい位置に点があるはずなので、検索半径を標準の半分にする
    NSArray *blocks = [self sortByDistanceFromPoint:pt
                                           maxCount:1 maxDistance:_searchDistance/2];
    if (blocks.count) {
        KLIMAxesBlock *axes = [[KLIMAxesBlock alloc] init];
        axes.distance = org.distance - 1;
        axes.block = blocks[0];
        return axes;
    }
    return nil;
}

/**
 * 与えられたX軸端点とY軸端点に対応するグリッドのコーナーの点の画素群を得る.
 * @param xa X軸上の軸端点
 * @param ya Y軸上の軸端点
 * @param center 中央の点の座標
 * @return 対応するコーナーの点の画素群、見つからなければnil
 */
- (KLIMLabelingBlock *)getCornerWithXEnd:(KLIMAxesBlock *)xa
                          yEnd:(KLIMAxesBlock *)ya center:(CGPoint)center
{
    CGPoint pt = KLCGPointAdd(xa.block.center, KLCGPointSubtract(ya.block.center, center));
    NSArray *blocks = [self sortByDistanceFromPoint:pt
                                           maxCount:4 maxDistance:_searchDistance];
    // 中央点と２つの端点の座標を元に推定される点と実際の点の距離の差が長さの5%以内（経験則）か
    CGFloat dmax = KLCGPointDistance(pt, center) * 0.05;
    for (NSInteger i = 0; i < blocks.count; i++) {
        KLIMLabelingBlock *block = blocks[i];
        if (KLCGPointDistance2(block.center, pt) < dmax * dmax) {
            if ([self isOnGridWithPoint:block.center
                              onNthGrid:xa.distance fromCenter:ya.block.center] &&
                    [self isOnGridWithPoint:block.center
                              onNthGrid:ya.distance fromCenter:xa.block.center]) {
                return block;
            }
        }
    }
    return nil;
}

/**
 * 与えられた点がグリッドのn番目だという想定が正しいかどうかを判定する.
 * @param point 点の座標
 * @param n グルッドの軸から何番目の点か
 * @param center pointに対応するグリッドの軸上の点
 * @return 与えられた点がグリッドのn番目だという想定が正しいかどうか
 */
- (BOOL)isOnGridWithPoint:(CGPoint)point onNthGrid:(NSInteger)n fromCenter:(CGPoint)center
{
    // 与えられた点から軸上の点に向かって4つ（但し軸に達してしまう場合はそれ以下）の点が想定する位置に存在するかを調べる
    CGPoint vec = KLCGPointDevide(KLCGPointSubtract(point, center), n);
    for (NSInteger i = n - 1; i > n - 4 && i > 1; i--) {
        CGPoint pt = KLCGPointAdd(center, KLCGPointMultiply(vec, i));
        
        NSArray *blocks = [self sortByDistanceFromPoint:pt
                                               maxCount:1 maxDistance:_searchDistance/2];
        if (!blocks.count) {
            return NO;
        }
        KLIMLabelingBlock *block = blocks[0];
        // 想定座標と点の距離が10ピクセル（経験値）以内か
        if (KLCGPointDistance2(block.center, pt) > 10 * 10) {
            return NO;
        }
    }
    return YES;
}

/**
 * 全画素群の中から、その中心位置が与えられた点に近いものを順に指定の個数まで求める.
 * @param pt 点
 * @param count 求める個数
 * @param distance 対象とする最大距離
 * @return ptに近い順に並んだ最大count個の画素群の配列
 */
- (NSArray *)sortByDistanceFromPoint:(CGPoint)pt maxCount:(NSInteger)count maxDistance:(CGFloat)distance
{
    CGFloat xmin = pt.x - distance;
    CGFloat xmax = pt.x + distance;
    CGFloat ymin = pt.y - distance;
    CGFloat ymax = pt.y + distance;
    
    NSMutableArray *nearBlocks = [NSMutableArray array];
    for (NSInteger i = 0; i < _blocks.count; i++) {
        KLIMLabelingBlock *block = _blocks[i];
        CGFloat cx = block.center.x;
        CGFloat cy = block.center.y;
        if (xmin < cx && cx < xmax && ymin < cy && cy < ymax) {
            block.work = (NSInteger)KLCGPointDistance2(pt, block.center);
            [nearBlocks addObject:block];
        }
    }
    
    NSSortDescriptor *desc = [NSSortDescriptor sortDescriptorWithKey:@"work" ascending:YES];
    [nearBlocks sortUsingDescriptors:[NSArray arrayWithObject:desc]];
    if (nearBlocks.count > count) {
        return [nearBlocks subarrayWithRange:NSMakeRange(0, count)];
    } else {
        return nearBlocks;
    }
}

/**
 * 配列で与えられた4つの画素群を左側、下側、右側、上側の順に並ベ直した配列を返す.
 * @param blocks 4つの画素群の配列
 * @return 左側、下側、右側、上側の順に並ベ直した配列
 */
- (NSArray *)sortByPosition:(NSArray *)blocks
{
    CGFloat xmin, xmax, ymin, ymax;
    KLIMLabelingBlock *xminB, *xmaxB, *yminB, *ymaxB;
    xminB = xmaxB = yminB = ymaxB = blocks[0];
    xmin = xmax = xminB.center.x;
    ymin = ymax = yminB.center.y;
    
    for (NSInteger i = 1; i < blocks.count; i++) {
        KLIMLabelingBlock *b = blocks[i];
        CGPoint p = b.center;
        if (p.x < xmin) {
            xmin = p.x, xminB = b;
        }
        if (p.x > xmax) {
            xmax = p.x, xmaxB = b;
        }
        if (p.y < ymin) {
            ymin = p.y, yminB = b;
        }
        if (p.y > ymax) {
            ymax = p.y, ymaxB = b;
        }
    }
    return [NSArray arrayWithObjects:xminB, yminB, xmaxB, ymaxB, nil];
}

@end
