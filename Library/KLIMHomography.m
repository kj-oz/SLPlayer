//
//  KLIMHomography.m
//  KLib Image
//
//  Created by KO on 13/10/18.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import "KLIMHomography.h"

@implementation KLIMHomography
{
    // 変換係数
    CGFloat _a1, _b1, _c1;
    CGFloat _a2, _b2, _c2;
    CGFloat _d, _e;
    
    // 元画像
    UInt8 *_srcBuffer;
    NSUInteger _srcWidth;
    NSUInteger _srcHeight;
}

#pragma mark - 処理

- (UIImage *)transformFromPoints:(CGPoint *)points ofImage:(UIImage *)image toSize:(CGSize)size
{
    CGFloat sx = (points[0].x-points[1].x)+(points[2].x-points[3].x);
    CGFloat sy = (points[0].y-points[1].y)+(points[2].y-points[3].y);
    
    CGFloat dx1 = points[1].x-points[2].x;
    CGFloat dx2 = points[3].x-points[2].x;
    CGFloat dy1 = points[1].y-points[2].y;
    CGFloat dy2 = points[3].y-points[2].y;
    
    CGFloat z = (dx1*dy2)-(dy1*dx2);
    _d = ((sx*dy2)-(sy*dx2))/z;
    _e = ((sy*dx1)-(sx*dy1))/z;
    
    _a1 = points[1].x-points[0].x+_d*points[1].x;
    _b1 = points[3].x-points[0].x+_e*points[3].x;
    _c1 = points[0].x;
    _a2 = points[1].y-points[0].y+_d*points[1].y;
    _b2 = points[3].y-points[0].y+_e*points[3].y;
    _c2 = points[0].y;
    
    _srcWidth = image.size.width;
    _srcHeight = image.size.height;
    _srcBuffer = malloc(_srcWidth * _srcHeight * 4);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(_srcBuffer, _srcWidth, _srcHeight, 8, _srcWidth * 4,
                                                 colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(context, CGRectMake(0, 0, _srcWidth, _srcHeight), image.CGImage);
    CGContextRelease(context);
    
    UInt8 *dstBuffer = malloc(size.width * size.height * 4);
    UInt8 *bufferPtr = dstBuffer;
    UInt8 color[3];
    
    for (NSInteger y = 0; y < size.height; y++) {
        for (NSInteger x = 0; x < size.width; x++) {
            CGPoint srcPt = [self invertFromPoint:CGPointMake(x/size.width , y/size.height)];
            [self getSourceColorOnPoint:srcPt color:color];
            *bufferPtr++ = color[0];
            *bufferPtr++ = color[1];
            *bufferPtr++ = color[2];
            bufferPtr++;
        }
    }
    
    NSData *data = [NSData dataWithBytes:dstBuffer length:size.width * size.height * 4];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGImageRef dstCGImage = CGImageCreate(size.width, size.height, 8, 32, size.width * 4,
                                          colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
                                          provider, NULL, false, kCGRenderingIntentDefault);
    
    // UIImageをCGImageから取得
    UIImage *dstImage = [UIImage imageWithCGImage:dstCGImage];
    
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(dstCGImage);
    CGDataProviderRelease(provider);
    free(dstBuffer);
    free(_srcBuffer);
    _srcBuffer = NULL;
    
    return dstImage;
}

#pragma mark - プライベートメソッド群

/**
 * 与えられた実数座標に基づいて周辺4ピクセルの画像より色を算出する.
 * @param point 座標
 * @param color 座標の色（出力、RGB3要素の配列）
 */
- (void)getSourceColorOnPoint:(CGPoint)point color:(UInt8 *)color
{
    CGFloat x = point.x;
    CGFloat y = point.y;
    x = MAX(0, MIN(_srcWidth - 1, x));
    y = MAX(0, MIN(_srcHeight - 1, y));
    
    // X座標に関する配分係数を得る
    double m, n;
    NSInteger x0 = (NSInteger)floorf(x);
    NSInteger x1 = (NSInteger)ceilf(x);
    
    NSInteger ox = 0;		// X方向のピクセルごとのオフセット(0で初期化)
    if (x0 == x1) {
        // Xがちょうどピクセル上
        m = 0.0; n = 1.0;
    } else {
        ox = 4;
        m = x - x0;
        n = x1 - x;
    }

    // Y座標に関する配分係数を得る
    double s, t;
    NSInteger y0 = (NSInteger)floorf(y);
    NSInteger y1 = (NSInteger)ceilf(y);
    
    NSInteger oy = 0;
    if (y0 == y1) {
        // Yがちょうどピクセル上
        s = 0.0; t = 1.0;
    } else {
        oy = _srcWidth * 4;
        s = y - y0;
        t = y1 - y;
    }
    
    // 周辺4ピクセルの色を取得
    UInt8 *p00 = _srcBuffer + (y0 * _srcWidth + x0) * 4;
    UInt8 *p01 = p00 + oy;
    UInt8 *p10 = p00 + ox;
    UInt8 *p11 = p01 + ox;
    
    // RGB毎の比例配分
    for (NSInteger i = 0; i < 3; i++) {
        color[i] = (UInt8)(t * (n * *p00++ + m * *p10++) +
                          s * (n * *p01++ + m * *p11++) + 0.5);
    }
}

/**
 * 出力画像の与えられた位置に対応する元画像上の座標を得る.
 * @param point 出力画像の位置（縦横とも0.0〜1.0で指定）
 * @return 元画像上の座標
 */
- (CGPoint)invertFromPoint:(CGPoint)point
{
    CGFloat denom = _d*point.x + _e*point.y + 1;
    return CGPointMake((_a1*point.x + _b1*point.y + _c1) / denom,
                       (_a2*point.x + _b2*point.y + _c2) / denom);
}

@end
