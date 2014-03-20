//
//  KLDBGUtil.m
//  KLib Debug
//
//  Created by KO on 12/05/03.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import "KLDBGUtil.h"

@implementation KLDBGUtil

#pragma mark - クラスメソッド

+ (const char*)strPoint_:(CGPoint)point withPrecision:(NSInteger)precision
{
    static char buffer[256];
    static char format[64];
    
    sprintf(format, "%%.%ldf/%%.%ldf", precision, precision);
    sprintf(buffer, format, point.x, point.y);
    return (const char*)buffer;
}

+ (const char*)strSize_:(CGSize)size withPrecision:(NSInteger)precision
{
    static char buffer[256];
    static char format[64];
    
    sprintf(format, "%%.%ldf/%%.%ldf", precision, precision);
    sprintf(buffer, format, size.width, size.height);
    return (const char*)buffer;
}

+ (const char*)strRect_:(CGRect)rect withPrecision:(NSInteger)precision
{
    static char buffer[256];
    
    sprintf(buffer, "orign:%s size:%s", 
            [KLDBGUtil strPoint_:rect.origin withPrecision:precision],
            [KLDBGUtil strSize_:rect.size withPrecision:precision]);
    return (const char*)buffer;
}

@end
