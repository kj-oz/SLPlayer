//
//  KLCGPointUtil.m
//  KLib CoreGraphics
//
//  Created by KO on 13/10/19.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import "KLCGPointUtil.h"

#pragma mark - 関数

CGFloat KLCGPointLength(CGPoint pt)
{
    CGFloat dx = pt.x;
    CGFloat dy = pt.y;
    return sqrtf(dx * dx + dy * dy);
}

CGFloat KLCGPointLength2(CGPoint pt)
{
    CGFloat dx = pt.x;
    CGFloat dy = pt.y;
    return dx * dx + dy * dy;
}

CGFloat KLCGPointDistance(CGPoint pt1, CGPoint pt2)
{
    CGFloat dx = pt2.x - pt1.x;
    CGFloat dy = pt2.y - pt1.y;
    return sqrtf(dx * dx + dy * dy);
}

CGFloat KLCGPointDistance2(CGPoint pt1, CGPoint pt2)
{
    CGFloat dx = pt2.x - pt1.x;
    CGFloat dy = pt2.y - pt1.y;
    return dx * dx + dy * dy;
}

CGPoint KLCGPointAdd(CGPoint pt1, CGPoint pt2)
{
    return CGPointMake(pt1.x + pt2.x, pt1.y + pt2.y);
}

CGPoint KLCGPointSubtract(CGPoint pt1, CGPoint pt2)
{
    return CGPointMake(pt1.x - pt2.x, pt1.y - pt2.y);
}

CGPoint KLCGPointMultiply(CGPoint pt, CGFloat multiplier)
{
    return CGPointMake(pt.x * multiplier, pt.y * multiplier);
}

CGPoint KLCGPointDevide(CGPoint pt, CGFloat divisor)
{
    return CGPointMake(pt.x / divisor, pt.y / divisor);
}

CGPoint KLCGPointMiddle(CGPoint pt1, CGPoint pt2)
{
    return CGPointMake((pt1.x + pt2.x) * 0.5, (pt1.y + pt2.y) * 0.5);
}

CGPoint KLCGPointNormlise(CGPoint pt)
{
    CGFloat divisor = KLCGPointLength(pt);
    return CGPointMake(pt.x / divisor, pt.y / divisor);
}