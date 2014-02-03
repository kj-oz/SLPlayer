//
//  KLDBGUtil.h
//  KLib Debug
//
//  Created by KO on 12/05/03.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG

/**
 * 標準出力に文字列を出力する.
 * @param ... 
 */
#define KLDBGPrint(...)                 printf(__VA_ARGS__)

/**
 * 標準出力に与えられた接頭句とともにメソッド名を出力する.
 * @param leader
 */
#define KLDBGPrintMethodName(leader)    printf("%s%s\n", leader, __func__)

/**
 * メソッド名を得る.
 * @return メソッド名
 */
#define KLDBGMethod()                   __func__

/**
 * 標準出力に与えられた点の内容を出力する.
 * @param point 点
 */
#define KLDBGPoint(point)               [KLDBGUtil strPoint_:point withPrecision:1]

/**
 * 標準出力に与えられたサイズの内容を出力する.
 * @param size サイズ
 */
#define KLDBGSize(size)                 [KLDBGUtil strSize_:size withPrecision:1]

/**
 * 標準出力に与えられた長方形の内容を出力する.
 * @param rect 長方形
 */
#define KLDBGRect(rect)                 [KLDBGUtil strRect_:rect withPrecision:1]

/**
 * 標準出力に与えられたオブジェクトのクラス名を出力する.
 * @param obj オブジェクト
 */
#define KLDBGClass(obj)                 ((obj).class.description.UTF8String)

#else
#define KLDBGPrint(...)
#define KLDBGPrintMethodName(leader)
#define KLDBGMethod()
#define KLDBGPoint(point)
#define KLDBGSize(size)
#define KLDBGRect(rect)
#define KLDBGClass(obj)
#endif

@interface KLDBGUtil : NSObject

/**
 * 与えれた点の指定の精度の内容文字列を得る.
 * @param point 点
 * @param precision 小数点以下桁数
 * @return 点の内容
 */
+ (const char*)strPoint_:(CGPoint)point withPrecision:(NSInteger)precision;

/**
 * 与えれたサイズの指定の精度の内容文字列を得る.
 * @param size サイズ
 * @param precision 小数点以下桁数
 * @return サイズの内容
 */
+ (const char*)strSize_:(CGSize)size withPrecision:(NSInteger)precision;

/**
 * 与えれた長方形の指定の精度の内容文字列を得る.
 * @param rect 長方形
 * @param precision 小数点以下桁数
 * @return 長方形の内容
 */
+ (const char*)strRect_:(CGRect)point withPrecision:(NSInteger)precision;

@end
