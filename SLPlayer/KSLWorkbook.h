//
//  KSLBook.h
//  SLPlayer
//
//  Created by KO on 2014/01/03.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSLProblem;

/**
 * 問題集を表すクラス.
 */
@interface KSLWorkbook : NSObject

// 一覧に表示する題名
@property (nonatomic, copy) NSString *title;

// 問題の配列
@property (nonatomic, readonly) NSArray *problems;

/**
 * 与えられた名称の問題集オブジェクトを生成する.
 * @param title 名称
 * @return 問題集オブジェクト
 */
- (id)initWithTitle:(NSString *)title;

- (void)addProblem:(KSLProblem *)problem withSave:(BOOL)save;

- (void)removeProblem:(KSLProblem *)problem withDelete:(BOOL)delete;

@end
