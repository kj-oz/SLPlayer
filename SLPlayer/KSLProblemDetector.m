//
//  KSLImageRecognizer.m
//  SLPlayer
//
//  Created by KO on 13/10/20.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import "KSLProblemDetector.h"
#import "KLIMBinaryImage.h"
#import "KLIMLabelingImage.h"
#import "KLIMLabelingBlock.h"
#import "KLIMPointGrid.h"
#import "KLIMHomography.h"
#import "KLIMNumberDetecter.h"
#import "KSLProblem.h"
#import "KLCGPointUtil.h"

@implementation KSLProblemDetector

#pragma mark - 処理

- (KSLProblem *)detectProblemFromImage:(UIImage *)image
{
    UIImage *orgImage = image;
//    NSInteger min = MIN(image.size.width, image.size.height);
//    NSInteger factor = (NSInteger)(min / 1000.0);
//    if (factor) {
//        // 対象の画像の大きさは、短辺が1000より小さくなる程度にリサイズ
//        factor++;
//        NSInteger w = image.size.width / factor;
//        NSInteger h = image.size.height / factor;
//        UIGraphicsBeginImageContext(CGSizeMake(w, h));
//        [image drawInRect:CGRectMake(0, 0, w, h)];
//        orgImage = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//    }
    
    // グリッド抽出用の２値化画像には適応的２値化を行い、膨張処理は行わない画像を使用
    KLIMBinaryImage *bin = [[KLIMBinaryImage alloc] initWithUIImage:orgImage];
//    UIImage *im = [bin createImage];
//    NSData *data = UIImagePNGRepresentation(im);
//    [data writeToFile:@"/Users/zak/Documents/Temp/bin.png" atomically:YES];
    
    
    KLIMPointGrid *grid = [[KLIMPointGrid alloc] initWithBinaryImage:bin];
    if (grid) {
        NSInteger numCol = grid.numCol;
        NSInteger numRow = grid.numRow;
        int *values = malloc(numCol * numRow * 4);
        int *v = values;
        for (NSInteger r = 0; r < numRow; r++) {
            for (NSInteger c = 0; c < numCol; c++) {
                *v++ = -1;
            }
        }
        
        NSInteger pitch = 60;
        UIImage *normalizedImage = [self createNormalizedImageWithGrid:grid pitch:pitch fromImage:orgImage];
        // 数値の認識用２値化画像も適応的２値化を行った画像を使用
        KLIMBinaryImage *normalizedBin = [[KLIMBinaryImage alloc] initWithUIImage:normalizedImage];
        
        KLIMLabelingImage *li = [[KLIMLabelingImage alloc] initWithBinaryImage:normalizedBin];
//        UIImage *im = [li createImage];
//        NSData *data = UIImagePNGRepresentation(im);
//        [data writeToFile:@"/Users/zak/Documents/Temp/normalizedLabel.png" atomically:YES];
        
        //NSInteger pitch = grid.pitch;
        
        // 以下のサイズチェック用の係数は経験則（pitch 40〜100程度の場合）
        NSInteger wmin = (NSInteger)(pitch * 0.2);
        NSInteger wmax = (NSInteger)(pitch * 0.7);
        NSInteger hmin = (NSInteger)(pitch * 0.5);
        NSInteger hmax = (NSInteger)(pitch * 0.8);
        KLIMNumberDetecter *nd = [[KLIMNumberDetecter alloc]
                                  initWithBorderCheckWidth:MIN(2, pitch * 0.1)];
        for (NSInteger i = 1; i < li.blocks.count; i++) {
            KLIMLabelingBlock *block = li.blocks[i];
            if (wmin < block.width && block.width < wmax &&
                hmin < block.height && block.height < hmax) {
                //NSInteger c = block.center.x / pitch;
                //NSInteger r = block.center.y / pitch;
                NSInteger c = block.xmin / pitch;
                NSInteger r = block.ymin / pitch;
                if (c == block.xmax / pitch && r == block.ymax / pitch) {
                    printf("%ld,%ld,", (long)c, (long)r);
                    NSInteger n = [nd detectWithBlock:block ofImage:normalizedBin];
                    if (n > 3) {
                        n = block.numHole ? 0 : 3;
                    }
                    values[r * numCol + c] = (int)n;
                }
            }
        }
        KSLProblem *problem = [[KSLProblem alloc] initWithWidth:numCol andHeight:numRow data:values];
        free(values);
        
        return problem;
    }
    return nil;
}

#pragma mark - プライベートメソッド

/**
 * ゆがみを補正してグリッドにマッチさせた画像を得る.
 * @param grid グリッド
 * @param pitch 出力画像のグリッドピッチ
 * @param orgImage 元画像
 * @return ゆがみを補正してグリッドにマッチさせた画像
 */
- (UIImage *)createNormalizedImageWithGrid:(KLIMPointGrid *)grid pitch:(CGFloat)pitch fromImage:(UIImage *)orgImage;
{
    // 正規化後のサイズ
    UIImage *parts[4];
//    NSInteger pitch = grid.pitch;
    NSInteger dx0 = pitch * grid.axesX;
    NSInteger dy0 = pitch * grid.axesY;
    NSInteger dx1 = pitch * grid.numCol - dx0;
    NSInteger dy1 = pitch * grid.numRow - dy0;
    KLIMHomography *homography = [KLIMHomography new];
    CGPoint pts[4];
    
    // 左上
    pts[0] = [grid ctrlBlockOfPosition:0].center;
    pts[1] = [grid ctrlBlockOfPosition:1].center;
    pts[2] = [grid ctrlBlockOfPosition:4].center;
    pts[3] = [grid ctrlBlockOfPosition:3].center;
    parts[0] = [homography transformFromPoints:pts ofImage:orgImage toSize:CGSizeMake(dx0, dy0)];
    
    // 右上
    pts[0] = [grid ctrlBlockOfPosition:1].center;
    pts[1] = [grid ctrlBlockOfPosition:2].center;
    pts[2] = [grid ctrlBlockOfPosition:5].center;
    pts[3] = [grid ctrlBlockOfPosition:4].center;
    parts[1] = [homography transformFromPoints:pts ofImage:orgImage toSize:CGSizeMake(dx1, dy0)];
    
    // 左下
    pts[0] = [grid ctrlBlockOfPosition:3].center;
    pts[1] = [grid ctrlBlockOfPosition:4].center;
    pts[2] = [grid ctrlBlockOfPosition:7].center;
    pts[3] = [grid ctrlBlockOfPosition:6].center;
    parts[2] = [homography transformFromPoints:pts ofImage:orgImage toSize:CGSizeMake(dx0, dy1)];
    
    // 右下
    pts[0] = [grid ctrlBlockOfPosition:4].center;
    pts[1] = [grid ctrlBlockOfPosition:5].center;
    pts[2] = [grid ctrlBlockOfPosition:8].center;
    pts[3] = [grid ctrlBlockOfPosition:7].center;
    parts[3] = [homography transformFromPoints:pts ofImage:orgImage toSize:CGSizeMake(dx1, dy1)];

    NSInteger width = grid.numCol * pitch;
    NSInteger height = grid.numRow * pitch;
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    
    [parts[0] drawInRect:CGRectMake(0, 0, parts[0].size.width, parts[0].size.height)];
    [parts[1] drawInRect:CGRectMake(parts[0].size.width, 0,
                                      parts[1].size.width, parts[1].size.height)];
    [parts[2] drawInRect:CGRectMake(0, parts[0].size.height,
                                      parts[2].size.width, parts[2].size.height)];
    [parts[3] drawInRect:CGRectMake(parts[0].size.width, parts[0].size.height,
                                      parts[3].size.width, parts[3].size.height)];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
