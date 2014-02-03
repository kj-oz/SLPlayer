//
//  KLCGPointUtil.h
//  KLib CoreGraphics
//
//  Created by KO on 13/10/19.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 原点から与えれた点までの距離を求める.
 * @param pt 点
 * @return 原点からの距離
 */
CGFloat KLCGPointLength(CGPoint pt);

/**
 * 原点から与えれた点までの距離の2乗を求める.
 * @param pt 点
 * @return 原点からの距離の2乗
 */
CGFloat KLCGPointLength2(CGPoint pt);

/**
 * 2点間の距離を求める.
 * @param pt1 点1
 * @param pt2 点2
 * @return 2点間の距離
 */
CGFloat KLCGPointDistance(CGPoint pt1, CGPoint pt2);

/**
 * 2点間の距離の2乗を求める.
 * @param pt1 点1
 * @param pt2 点2
 * @return 2点間の距離の2乗
 */
CGFloat KLCGPointDistance2(CGPoint pt1, CGPoint pt2);

/**
 * 2点のベクトルの和を求める.
 * @param pt1 点1
 * @param pt2 点2
 * @return 2点のベクトルの和
 */
CGPoint KLCGPointAdd(CGPoint pt1, CGPoint pt2);

/**
 * 2点のベクトルの差（pt1-pt2）を求める.
 * @param pt1 点1
 * @param pt2 点2
 * @return 2点のベクトルの差
 */
CGPoint KLCGPointSubtract(CGPoint pt1, CGPoint pt2);

/**
 * 与えられた点のベクトルの実数倍のベクトルを求める.
 * @param pt 点
 * @param multiplier 乗数
 * @return 乗数倍のベクトル
 */
CGPoint KLCGPointMultiply(CGPoint pt, CGFloat multiplier);

/**
 * 与えられた点のベクトルの実数分の1倍のベクトルを求める.
 * @param pt 点
 * @param divisor 除数
 * @return 除数分の1倍のベクトル
 */
CGPoint KLCGPointDevide(CGPoint pt, CGFloat divisor);

/**
 * 2点の中点を求める.
 * @param pt1 点1
 * @param pt2 点2
 * @return 2点の中点
 */
CGPoint KLCGPointMiddle(CGPoint pt1, CGPoint pt2);

/**
 * 与えられた点のベクトルを長さ1に正規化したベクトルを求める.
 * @param pt 点
 * @return 長さ1に正規化したベクトル
 */
CGPoint KLCGPointNormlise(CGPoint pt);
