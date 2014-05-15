//
//  KLIMBinaryImage.m
//  KLib Image
//
//  Created by KO on 13/10/13.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import "KLIMBinaryImage.h"
#include <CommonCrypto/CommonDigest.h>

@implementation KLIMBinaryImage

#pragma mark - 初期化

- (id)initWithUIImage:(UIImage *)image threshold:(CGFloat)threshold
{
    self = [super init];
    if (self) {
        CGImageRef cgImage = image.CGImage;
        _width = image.size.width;
        _height = image.size.height;
        
        CGDataProviderRef dataProvider = CGImageGetDataProvider(cgImage);
        CFDataRef dataRef = CGDataProviderCopyData(dataProvider);
        UInt8* imagePtr = (UInt8 *)CFDataGetBytePtr(dataRef);
        size_t bytesPerRow = CGImageGetBytesPerRow(cgImage);
        
        _buffer = malloc(_width * _height);
        UInt8 *bufferPtr = _buffer;
        
        for (NSInteger y = 0; y < _height; y++) {
            UInt8 *pixelPtr = imagePtr + y * bytesPerRow;
            for (NSInteger x = 0; x < _width; x++) {
                // 色情報を取得する
                UInt8 b = *pixelPtr++;  // 青
                UInt8 g = *pixelPtr++;  // 緑
                UInt8 r = *pixelPtr++;  // 赤
                pixelPtr++;
                
                CGFloat yy = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
                UInt8 p = yy > threshold ? 0 : 255;
                *bufferPtr++ = p;
            }
        }
        CFRelease(dataRef);
    }
    return self;
}

- (id)initWithUIImage:(UIImage *)image
{
    self = [super init];
    if (self) {
        CGImageRef cgImage = image.CGImage;
        _width = image.size.width;
        _height = image.size.height;
        
        CGDataProviderRef dataProvider = CGImageGetDataProvider(cgImage);
        CFDataRef dataRef = CGDataProviderCopyData(dataProvider);
        UInt8* imagePtr = (UInt8 *)CFDataGetBytePtr(dataRef);
        size_t bytesPerRow = CGImageGetBytesPerRow(cgImage);
        
        _buffer = malloc(_width * _height);
        memset(_buffer, 0, _width * _height);
        UInt8 *bufferPtr = _buffer;
        
        UInt32 *accumBuffer = malloc(_width * _height * 4);
        memset(accumBuffer, 0, _width * _height * 4);
        UInt32 *accumPtr = accumBuffer;
        
        for (NSInteger y = 0; y < _height; y++) {
            UInt8 *pixelPtr = imagePtr + y * bytesPerRow;
            for (NSInteger x = 0; x < _width; x++) {
                // 色情報を取得する
                UInt8 b = *pixelPtr++;  // 青
                UInt8 g = *pixelPtr++;  // 緑
                UInt8 r = *pixelPtr++;  // 赤
                pixelPtr++;
                
                int p = (int)(0.299 * r + 0.587 * g + 0.114 * b);
                *bufferPtr++ = (UInt8)p;
                *accumPtr = p;
                if (x) *accumPtr += *(accumPtr - 1);
                if (y) {
                    UInt32 *upPtr = accumPtr - _width;
                    *accumPtr += *upPtr;
                    if (x) *accumPtr -= *(upPtr - 1);
                }
                accumPtr++;
            }
        }
        
        CFRelease(dataRef);
        
        bufferPtr = _buffer;
        NSInteger R = _width / 8;
        for (NSInteger y = 0; y < _height; y++) {
            NSInteger ymin = MAX(0, y - R);
            NSInteger ymax = MIN(_height - 1, y + R);
            NSInteger iymin = ymin ? (ymin - 1) * _width : 0;
            NSInteger iymax = ymax * _width;
            for (NSInteger x = 0; x < _width; x++) {
                NSInteger xmin = MAX(0, x - R);
                NSInteger xmax = MIN(_width - 1, x + R);
                UInt32 sum = accumBuffer[iymax + xmax];
                if (xmin) {
                    sum -= accumBuffer[iymax + xmin];
                }
                if (ymin) {
                    sum -= accumBuffer[iymin + xmax];
                    if (xmin) {
                        sum += accumBuffer[iymin + xmin];
                    }
                }
                NSInteger val = *bufferPtr * (xmax - xmin + 1) * (ymax - ymin + 1);
                sum *= 0.75;
                UInt8 p = val < sum ? 255 : 0;
                *bufferPtr++ = p;
            }
        }
        free(accumBuffer);
    }
    return self;
}

- (id)initWithBinaryImage:(KLIMBinaryImage *)image
{
    self = [super init];
    if (self) {
        _width = image.width;
        _height = image.height;
        
        // int bufferSize = _width * _height * 4;
        NSInteger bufferSize = _width * _height;
        _buffer = malloc(bufferSize);
        
        memcpy(_buffer, image.buffer, bufferSize);
    }
    return self;
}

- (void)dealloc
{
    free(_buffer);
}

#pragma mark - 加工処理

- (void)contract
{
    NSInteger bufferSize = _width * _height;
    UInt8 *buffer = malloc(bufferSize);
    
    memcpy(buffer, _buffer, bufferSize);
    
    //収縮
    for(NSInteger y = 2; y < _height - 2; y++) {
        for(NSInteger x = 2; x < _width - 2; x++) {
            NSInteger c = y * _width + x;
            NSInteger b = 1;
            if (!buffer[c]) {
                b = 0;
            } else {
                //1-画素のときだけ調査
                if (!(buffer[c+1] && buffer[c-1] && buffer[c+_width] && buffer[c-_width] &&
                        buffer[c+1+_width] && buffer[c+1-_width] &&
                        buffer[c-1+_width] && buffer[c-1-_width])) {
                    b = 0;
                }
            }
            _buffer[c] = b == 1 ? 255 : 0;
        }
    }
    free(buffer);
}

- (void)expand
{
    NSInteger bufferSize = _width * _height;
    UInt8 *buffer = malloc(bufferSize);
        
    memcpy(buffer, _buffer, bufferSize);
    
    //膨張
    for(NSInteger y = 2; y < _height - 2; y++) {
        for(NSInteger x = 2; x < _width - 2; x++) {
            NSInteger c = y * _width + x;
            NSInteger b = 0;
            if (buffer[c]) {
                b = 1;
            } else {
                //0-画素のときだけ調査
                if (buffer[c+1] || buffer[c-1] || buffer[c+_width] || buffer[c-_width] ||
                      buffer[c+1+_width] || buffer[c+1-_width] ||
                      buffer[c-1+_width] || buffer[c-1-_width]) {
                    b = 1;
                }
            }
            _buffer[c] = b == 1 ? 255 : 0;
        }
    }
    free(buffer);
}

- (void)ensureClearEdge
{
    NSInteger y = _height - 1;
    for (NSInteger x = 0; x < _width; x++) {
        _buffer[x] = 0;
        _buffer[y * _width + x] = 0;
    }
    for (NSInteger y = 1; y < _height - 1; y++) {
        _buffer[(y - 1) * _width + 1] = 0;
        _buffer[y * _width] = 0;
    }
}

- (void)removeCrumb
{
    NSInteger bufferSize = _width * _height;
    UInt8 *buffer = malloc(bufferSize);
    
    memcpy(buffer, _buffer, bufferSize);
    
    for(NSInteger y = 1; y < _height - 1; y++) {
        for(NSInteger x = 1; x < _width - 1; x++) {
            NSInteger c = y * _width + x;
            NSInteger b = buffer[c];
            if (b) {
                if (!(buffer[c+1] || buffer[c-1] || buffer[c+_width] || buffer[c-_width] ||
                      buffer[c+1+_width] || buffer[c+1-_width] ||
                      buffer[c-1+_width] || buffer[c-1-_width])) {
                    _buffer[c] = 0;
                }
            } else {
                if (buffer[c+1] && buffer[c-1] && buffer[c+_width] && buffer[c-_width] &&
                      buffer[c+1+_width] && buffer[c+1-_width] &&
                      buffer[c-1+_width] && buffer[c-1-_width]) {
                    _buffer[c] = 255;
                }
            }
        }
    }
    free(buffer);
}

#pragma mark - 出力

- (UIImage *)createImage
{
    UInt8 *imagePtr = malloc(self.width * self.height * 4);
    // UInt32 *bufferPtr = self.buffer;
    UInt8 *bufferPtr = self.buffer;
    
    for (NSInteger y = 0; y < _height; y++) {
        for (NSInteger x = 0; x < _width; x++) {
            
            // ピクセルのポインタを取得する
            UInt8* pixelPtr = imagePtr + (y * self.width + x) * 4;
            UInt8 p = *bufferPtr++;

            // 色情報を取得する
            *pixelPtr++ = p;
            *pixelPtr++ = p;
            *pixelPtr++ = p;
            *pixelPtr = 255;
        }
    }

    NSData *data = [NSData dataWithBytes:imagePtr length:self.width * self.height * 4];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    // IplImageのデータからCGImageを作成
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage = CGImageCreate(self.width, self.height, 8, 32, self.width * 4,
                        colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast,
                        provider, NULL, false, kCGRenderingIntentDefault);
    
    // UIImageをCGImageから取得
    UIImage *ret = [UIImage imageWithCGImage:cgImage];
    
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    free(imagePtr);
    return ret;
}

@end
