//
//  KLCGUtil.m
//  SLPlayer
//
//  Created by KO on 2014/01/22.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import "KLCGUtil.h"

#pragma mark - 関数

CGFloat KLCGClumpValue(CGFloat value, CGFloat min, CGFloat max)
{
    return value < min ? min : value > max ? max : value;
}

int KLCGClumpInt(int value, int min, int max)
{
    return value < min ? min : value > max ? max : value;
}

CGRect KLCGClumpRect(CGRect rect, CGRect border)
{
    CGFloat x = rect.size.width > border.size.width ? border.origin.x :
        KLCGClumpValue(rect.origin.x, border.origin.x, CGRectGetMaxX(border) - rect.size.width);
    CGFloat y = rect.size.height > border.size.height ? border.origin.y :
        KLCGClumpValue(rect.origin.y, border.origin.y, CGRectGetMaxY(border) - rect.size.height);
    return CGRectMake(x, y, rect.size.width, rect.size.height);
}