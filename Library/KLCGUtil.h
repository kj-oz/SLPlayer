//
//  KLCGUtil.h
//  SLPlayer
//
//  Created by KO on 2014/01/22.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * 与えられた値を与えられた最小値と最大値の間に含まれるよう補正する.
 * @param value 値
 * @param min 最小値
 * @param max 最大値
 * @return 補正後の値
 */
CGFloat KLCGClumpValue(CGFloat value, CGFloat min, CGFloat max);

/**
 * 与えられた整数値を与えられた最小値と最大値の間に含まれるよう補正する.
 * @param value 値
 * @param min 最小値
 * @param max 最大値
 * @return 補正後の値
 */
NSInteger KLCGClumpInt(NSInteger value, NSInteger min, NSInteger max);

/**
 * 与えられた長方形の位置を、与えられた境界長方形内に入るように補正する.
 * 長方形の幅が境界の幅より大きい場合には、左辺のX座標を境界の左辺に合わせる.
 * 長方形の高さが境界の高さより大きい場合には、上辺のY座標を境界の上辺に合わせる
 * @param rect 対象長方形
 * @param border 境界長方形
 * @return 補正後の長方形
 */
CGRect KLCGClumpRect(CGRect rect, CGRect border);
