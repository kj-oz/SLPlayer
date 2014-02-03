//
//  KSLBook.h
//  SLPlayer
//
//  Created by KO on 2014/01/03.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 問題集を表すクラス.
 */
@interface KSLWorkbook : NSObject

// 一覧に表示する題名
@property (nonatomic, copy) NSString *title;

// 問題の配列
@property (nonatomic, readonly) NSArray *problems;

/**
 * 与えられたディレクトリーの内容から問題集オブジェクトを生成する.
 * @param path ディレクトリーのパス
 * @return 問題種オブジェクト
 */
- (id)initWithDirectory:(NSString *)path;

@end
