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
#import "KLIMHistgram.h"

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


#pragma mark - KLIMAxes

/**
 * グリッドの軸上の画素群を管理するクラス.
 */
@interface KLIMAxes : NSObject

/**
 * 与えられた画素群の配列からAxesオブジェクトを生成する.
 * @param blocks 画素群の配列
 * @return その画素群からなる軸オブジェクト
 */
- (id)initWithBlocks:(NSMutableArray *)blocks;

/**
 * 最も遠い画素群に対するオブジェクトを返す.このオブジェクトは管理対象から外される（従って
 * 次にこのメソッドを呼び出す　と次ぎに遠いオブジェクトが返る）
 * @return 座標軸上の画素群.
 */
- (KLIMAxesBlock *)farthestBlock;

@end

@implementation KLIMAxes
{
    NSMutableArray *_blocks;
}

- (id)initWithBlocks:(NSMutableArray *)blocks
{
    self = [super init];
    if (self) {
        _blocks = blocks;
    }
    return self;
}

- (KLIMAxesBlock *)farthestBlock
{
    KLIMLabelingBlock *block = [_blocks lastObject];
    if (block) {
        [_blocks removeLastObject];
    }
    KLIMAxesBlock *axes = [[KLIMAxesBlock alloc] init];
    axes.distance = _blocks.count + 2;
    axes.block = block;
    return axes;
}

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
    
    // 点とみなすアスペクト比
    CGFloat _lRatio;
    
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
        UIImage *im = [_li createImage];
        NSData *data = UIImagePNGRepresentation(im);
        [data writeToFile:@"/Users/zak/Documents/Temp/label.png" atomically:YES];
        
        // 点の大きさは概ね0.5〜1.0mm、新書版が幅10cm、ジャイアント版が15cm、写真のサイズが1.1〜1.5倍とすると
        
        // 大きな画像で10X10の問題を想定し、長さのヒストグラムの最大は64、面積のヒストグラムの最大は64*64とする
        // それより大きなラベルはグリッド点以外とみなす
        NSInteger minL = image.width / 400;
        NSInteger maxL = image.width / 50;
        NSInteger bandL = 1;
        NSInteger minA = minL * minL;
        NSInteger maxA = (maxL + 1) * (maxL + 1) - 1;
        NSInteger bandA = 4;
        _lRatio = 0.8;
        
        KLIMHistgram *hArea = [[KLIMHistgram alloc] initWithMin:minA max:maxA bandWidth:bandA];
        KLIMHistgram *hLen = [[KLIMHistgram alloc] initWithMin:minL max:maxL bandWidth:bandL];
        BOOL dummy = YES;
        for (KLIMLabelingBlock *block in _li.blocks) {
            if (!dummy) {
                block.work = 0;
                int x = (int)block.width;
                int y = (int)block.height;
                int a = (int)block.area;
                
                if (minL <= x && x <= maxL &&
                        minL <= y && y <= maxL &&
                        minA <= a && a <= maxA &&
                        [self isCirclePointWithX:x y:y a:a]) {
                    block.work = 1;
                    [hLen addValue:x];
                    [hLen addValue:y];
                    [hArea addValue:a];
                }
            } else {
                // 最初のダミー要素読み飛ばし
                dummy = NO;
            }
        }
        KLDBGPrint("長さ\n");
        [hLen dump];
        KLDBGPrint("面積\n");
        [hArea dump];
        
        NSInteger peak = [hLen findPeak];
        NSInteger min = [hLen findPrevBottom:peak limit:0.2];
        if (min >= 0) {
            minL = (NSInteger)([hLen minAtIndex:min] / 1.2);
        }
        NSInteger max = [hLen findNextBottom:peak limit:0.2];
        if (max >= 0) {
            maxL = (NSInteger)([hLen maxAtIndex:max] * 1.2);
        }
        
        peak = [hArea findPeak];
        min = [hArea findPrevBottom:peak limit:0.2];
        if (min >= 0) {
            minA = (NSInteger)([hArea minAtIndex:min] / 1.44);
        }
        max = [hArea findNextBottom:peak limit:0.2];
        if (max >= 0) {
            maxA = (NSInteger)([hArea maxAtIndex:max] * 1.44);
        }
        
        // ヒストグラムから判明した範囲でフィルタリング
        _blocks = [NSMutableArray array];
        NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
        for (NSInteger i = 1; i < _li.blocks.count; i++) {
            KLIMLabelingBlock *block = _li.blocks[i];
        
            if (block.work &&
                    minL <= block.width && block.width <= maxL &&
                    minL <= block.height && block.height <= maxL &&
                    minA <= block.area && block.area <= maxA) {
                [_blocks addObject:block];
                [indexes addIndex:i];
            }
        }
        im = [_li createImageWithFilter:indexes];
        data = UIImagePNGRepresentation(im);
        [data writeToFile:@"/Users/zak/Documents/Temp/labelfilter.png" atomically:YES];
        
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

- (BOOL)isCirclePointWithX:(int)x y:(int)y a:(int)a
{
    float fx = (float)x;
    float fy = (float)y;
    float lRatio = x > y ? fy / fx : fx / fy;
    float aFactor = a / fx / fy;
    return (lRatio >= _lRatio && aFactor >= 0.5);
}

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
    KLIMAxes *xAxes0 = [self getAxesOfBasePoint:xminP center:cp maxLength:cp.x];
    KLIMAxes *xAxes1 = [self getAxesOfBasePoint:xmaxP center:cp maxLength:(_bin.width - cp.x)];
    if (!xAxes0 || !xAxes1) {
        return NO;        
    }
    KLIMAxesBlock *xa0 = [xAxes0 farthestBlock];
    KLIMAxesBlock *xa1 = [xAxes1 farthestBlock];

    // Y軸の仮確定
    KLIMAxes *yAxes0 = [self getAxesOfBasePoint:yminP center:cp maxLength:cp.y];
    KLIMAxes *yAxes1 = [self getAxesOfBasePoint:ymaxP center:cp maxLength:(_bin.height - cp.y)];
    if (!yAxes0 || !yAxes1) {
        return NO;
    }
    KLIMAxesBlock *ya0 = [yAxes0 farthestBlock];
    KLIMAxesBlock *ya1 = [yAxes1 farthestBlock];
    
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
                xa0 = [xAxes0 farthestBlock];
                if (!xa0) {
                    return NO;
                }
                continue;
            } else {
                ya0 = [yAxes0 farthestBlock];
                if (!ya0) {
                    return NO;
                }
                c10 = nil;
                continue;
            }
        }
        
        if (!c10) {
            if (!c11) {
                xa1 = [xAxes1 farthestBlock];
                if (!xa1) {
                    return NO;
                }
                continue;
            } else {
                ya0 = [yAxes0 farthestBlock];
                if (!ya0) {
                    return NO;
                }
                c00 = nil;
                continue;
            }
        }
        
        if (!c01) {
            ya1 = [yAxes1 farthestBlock];
            if (!ya1) {
                return NO;
            }
            c11 = nil;
            continue;
        }
        
        if (!c11) {
            ya1 = [yAxes1 farthestBlock];
            if (!ya1) {
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
 * 与えられた中央の点とその次の点を元に、延長上の画素群を見つけ出し軸オブジェクトを構築する.
 * @param bp 中央近傍の軸の起点の座標
 * @param center 中央の座標
 * @param length 端点を探す最大の距離
 * @return 与えられた起点の延長上の端点の画素群とその距離
 */
- (KLIMAxes *)getAxesOfBasePoint:(CGPoint)bp center:(CGPoint)center maxLength:(CGFloat)length
{
    CGPoint bvec = KLCGPointSubtract(bp, center);
    CGFloat pitch = KLCGPointLength(bvec);
    CGFloat dmax = pitch * 0.05;
    NSInteger imax = length / pitch;
    
    NSMutableArray *axesBlocks = [NSMutableArray array];
    CGPoint prevPt = center;
    CGPoint currPt = bp;
    
    for (NSInteger i = 2; i <= imax; i++) {
        CGPoint nextPt = KLCGPointAdd(currPt, KLCGPointSubtract(currPt, prevPt));
        
        NSArray *blocks = [self sortByDistanceFromPoint:nextPt
                                               maxCount:1 maxDistance:_searchDistance];
        KLIMLabelingBlock *block = blocks[0];
        // 直前の2点の座標を元に推定される点と実際の点の距離の差が長さの5%以内（経験則）か
        if (KLCGPointDistance2(block.center, nextPt) < dmax * dmax) {
            [axesBlocks addObject:block];
        } else {
            break;
        }
        
        prevPt = currPt;
        currPt = block.center;
    }
    if (axesBlocks.count) {
        return [[KLIMAxes alloc] initWithBlocks:axesBlocks];
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
    // 想定座標と点の距離が中心と端部の距離の2%以内か（経験則）
    CGFloat dmax = KLCGPointDistance(point, center) * 0.03;
    for (NSInteger i = n - 1; i >= n / 2 && i > 2; i--) {
         CGPoint pt = KLCGPointAdd(center, KLCGPointMultiply(vec, i));
        
        NSArray *blocks = [self sortByDistanceFromPoint:pt
                                               maxCount:1 maxDistance:_searchDistance/2];
        if (!blocks.count) {
            return NO;
        }
        KLIMLabelingBlock *block = blocks[0];
        if (KLCGPointDistance2(block.center, pt) > dmax * dmax) {
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
