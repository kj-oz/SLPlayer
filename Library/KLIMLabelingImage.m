//
//  KLIMLabelingImage.m
//  KLib Image
//
//  Created by KO on 13/10/14.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import "KLIMLabelingImage.h"
#import "KLIMBinaryImage.h"
#import "KLIMLabelingBlock.h"

@implementation KLIMLabelingImage

#pragma mark - 初期化

- (id)initWithBinaryImage:(KLIMBinaryImage *)image
{
    self = [super init];
    if (self) {
        image = [[KLIMBinaryImage alloc] initWithBinaryImage:image];
        [image ensureClearEdge];
        [image removeCrumb];
        
        _width = image.width;
        _height = image.height;
        _pixels = malloc(_width * _height * 4);
        memset(_pixels, 0, _width * _height * 4);
        
        _blocks = [NSMutableArray array];
        [_blocks addObject:[NSNull null]];
        NSInteger label = 0;  //最初のラベル番号 - 1
        NSInteger code;
        //始点の調査
        for (NSInteger y = 1; y < _height - 1; y++) {
            for (NSInteger x = 1; x < _width - 1; x++) {
                NSInteger c = y * _width + x;
                if (image.buffer[c] && !_pixels[c]) {
                    // 未追跡
                    if (!image.buffer[c-1]) {
                        // 左側が0-画素
                        code = 7;
                        label++; // ラベル番号の更新
                        [_blocks addObject:[[KLIMLabelingBlock alloc] initWithLabel:label]];
                        [self labelingBorderWithX:x y:y code:code label:label binBuffer:image.buffer]; //外側境界
                    } else if (!image.buffer[c+1]) {
                        // 右側が0-画素
                        code = 3;
                        NSInteger label0 = 0; //仮の値
                        for (NSInteger xi = 1; xi < x - 1; xi++) {
                            if (_pixels[c-xi]) {
                                label0 = _pixels[c-xi];   //外側境界のラベルと同じくする
                                break;
                            }
                        }
                        KLIMLabelingBlock *block = _blocks[label0];
                        block.numHole++;
                        [self labelingBorderWithX:x y:y code:code label:label0 binBuffer:image.buffer]; //内側境界
                    }
                }
            }
        }
        
        //内側のラベリング
        for (NSInteger y = 1; y < _height - 1; y++) {
            for (NSInteger x = 1; x < _width; x++) {
                NSInteger c = y * _width + x;
                if (_pixels[c] && !_pixels[c-1]) {
                    [_blocks[_pixels[c]] addPixelWithX:x andY:y];
                }
                if (image.buffer[c] && _pixels[c-1]) {
                    _pixels[c] = _pixels[c-1];
                    [_blocks[_pixels[c]] addPixelWithX:x andY:y];
                }
            }
        }
        
//        for (int i = 1; i <= label; i++) {
//            KLIMLabelingBlock* block = _blocks[i];
//            NSLog(@"%d: %d/%d %d-%d %d", block.label,
//                  block.xmin, block.ymin, block.width, block.height, block.area);
//        }
    }
    return self;
}

- (void)dealloc
{
    free(_pixels);
}

#pragma mark - 出力

- (UIImage *)createImage
{
    return [self createImageWithFilter:nil];
}
                
- (UIImage *)createImageWithFilter:(NSIndexSet *)labels
{
    UInt8 *imagePtr = malloc(self.width * self.height * 4);
    UInt32 *bufferPtr = self.pixels;
    
    for (NSInteger y = 0; y < _height; y++) {
        for (NSInteger x = 0; x < _width; x++) {
            
            // ピクセルのポインタを取得する
            UInt8* pixelPtr = imagePtr + (y * self.width + x) * 4;
            UInt32 p = *bufferPtr++;
            if (labels && ![labels containsIndex:p]) {
                p = 0;
            }
            
            // 色情報を取得する
            int b = p ? (p * 53 + 81) % 255 : 255;
            int g = p ? (p * 53 + 41) % 255 : 255;
            int r = p ? (p * 53) % 255 : 255;
            *pixelPtr++ = b;
            *pixelPtr++ = g;
            *pixelPtr++ = r;
            *pixelPtr = 255;
        }
    }
    
    NSData *data = [NSData dataWithBytes:imagePtr length:self.width * self.height * 4];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    // IplImageのデータからCGImageを作成
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage = CGImageCreate(self.width, self.height, 8, 32, self.width * 4,
                                       colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
                                       provider, NULL, false, kCGRenderingIntentDefault);
    
    // UIImageをCGImageから取得
    UIImage *ret = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    free(imagePtr);
    return ret;
}

#pragma mark - プライベートメソッド

/**
 * 境界線のラベリング(8−連結)を行う.
 * @param x 起点のX座標
 * @param y 起点のY座標
 * @param code 追跡を開始する方向コード(0:下、1:右下、2:右、3:右上、4:上、5:左上、6:左、7:左下)
 * @param label 番号
 * @param bin 2値化画像のバッファ
 */
- (void)labelingBorderWithX:(NSInteger)x y:(NSInteger)y code:(NSInteger)code label:(NSInteger)label binBuffer:(UInt8 *)bin
{
    NSInteger startX, startY; //始点
    NSInteger x1, y1;         //現在位置
    NSInteger x2, y2;         //探索位置
    
    startX = x; x1 = x;
    startY = y; y1 = y;
    
    x2 = 0; y2 = 0;
    while (x2 != startX || y2 != startY) {
        switch (code) {
            case 0: //下を調査
                x2 = x1; y2 = y1 + 1;
                if (bin[y2*_width+x2]) code = 6;
                else code = 1;
                break;
            case 1: //右下
                x2 = x1 + 1; y2 = y1 + 1;
                if (bin[y2*_width+x2]) code = 7;
                else code = 2;
                break;
            case 2: //右を調査
                x2 = x1 + 1; y2 = y1;
                if (bin[y2*_width+x2]) code = 0;
                else code = 3;
                break;
            case 3: //右上
                x2 = x1 + 1; y2 = y1 - 1;
                if (bin[y2*_width+x2]) code = 1;
                else code = 4;
                break;
            case 4: //上を調査
                x2 = x1; y2 = y1 - 1;
                if (bin[y2*_width+x2]) code = 2;
                else code = 5;
                break;
            case 5: //左上を調査
                x2 = x1 - 1; y2 = y1 - 1;
                if (bin[y2*_width+x2]) code = 3;
                else code = 6;
                break;
            case 6: //左を調査
                x2 = x1 - 1; y2 = y1;
                if (bin[y2*_width+x2]) code = 4;
                else code = 7;
                break;
            case 7: //左下を調査
                x2 = x1 - 1; y2 = y1 + 1;
                if (bin[y2*_width+x2]) code = 5;
                else code = 0;
                break;
        }
        
        if (bin[y2*_width+x2]) {
            _pixels[y2*_width+x2] = (UInt32)label;
            x1 = x2; y1 = y2;   //現在位置の更新
        }
    }
}

@end
