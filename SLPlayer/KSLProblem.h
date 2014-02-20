//
//  KSLProblem.h
//  SLPlayer
//
//  Created by KO on 13/11/02.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - 定数

/**
 * 動作を巻き戻せるよう処理履歴に残すアクションの種類の定義
 */
typedef enum {
    KSLActionTypeEdgeStatus,        // Edgeの状態の変更
    KSLActionTypeOppositeNode,      // Nodeの(一連の辺の)逆端のNodeを変更
    KSLActionTypeLUGateStatus,      // Nodeの右下から左上方向へのGateの状態の変更
    KSLActionTypeRUGateStatus,      // Nodeの左下から右上方向へのGateの状態の変更
    KSLActionTypeCellNumber         // Cellの数値の変更（Edit時）
} KSLActionType;

/**
 * 問題の状態
 */
typedef enum {
    KSLProblemStatusEditing,        // 編集中
    KSLProblemStatusNotStarted,     // 未着手
    KSLProblemStatusSolving,        // 未了
    KSLProblemStatusSolved          // 完了
} KSLProblemStatus;


#pragma mark - KSLAction

/**
 * 処理履歴に残す何らかの処理を表すクラス.
 */
@interface KSLAction : NSObject

// アクションの種類
@property (nonatomic, readonly) KSLActionType type;

// アクションの対象
@property (nonatomic, readonly) id target;

// 実行前の値
@property (nonatomic, readonly) int oldValue;

// 実行後の値
@property (nonatomic, readonly) int newValue;

/**
 * 与えられたパラメータの新規のアクションを生成する.
 * @param aType 種類
 * @param aTarget 対象
 * @param aOldValue; 実行前の値
 * @param aNewValue; 実行後の値
 * @return 新たなアクション
 */
- (id)initWithType:(KSLActionType)aType target:(id)aTarget
         fromValue:(int)aOldValue toValue:(int)aNewValue;

@end


#pragma mark - KSLProblem

/**
 * スリザーリンクの問題を表すクラス.
 */
@interface KSLProblem : NSObject

// ユニークなID
@property (nonatomic, readonly) NSString *uid;

// 一覧に表示する名称
@property (nonatomic, copy) NSString *title;

// 問題の状態
@property (nonatomic, assign) KSLProblemStatus status;

// 難易度
@property (nonatomic, assign) NSInteger difficulty;

// 感想、評価
@property (nonatomic, assign) NSInteger evaluation;

// 水平方向のセルの数
@property (nonatomic, readonly) NSInteger width;

// 垂直方向のセルの数
@property (nonatomic, readonly) NSInteger height;

// セルの数値の配列（空のセルは-1）
@property (nonatomic, readonly) NSArray *data;

// 解くにかかった秒数の配列（完了した回数分＋未了であればその分）
@property (nonatomic, strong) NSArray *elapsedSeconds;

/**
 * 与えられたサイズとデータの問題を生成する.
 * @param width 幅
 * @param height 高さ
 * @param data 数字の（C形式の）配列
 * @return 問題オブジェクト
 */
- (id)initWithWidth:(NSInteger)width andHeight:(NSInteger)height data:(NSInteger *)data;

/**
 * 与えられたパスのファイルから問題を読み込む.
 * @param path jsonファイルのパス
 * @return 問題オブジェクト
 */
- (id)initWithFile:(NSString *)path;

/**
 * 与えられた問題のコピーを生成する.
 * @param original 元の問題
 * @return 問題オブジェクト
 */
- (id)initWithProblem:(KSLProblem *)original;

/**
 *
 * @param original 
 */
- (void)updateWithProblem:(KSLProblem *)original;

/**
 * 与えられたディレクトリーの下に問題をjson形式のファイルとして保存する.
 * @param directory 保存先ディレクトリー
 */
- (void)saveToFile:(NSString *)directory;

/**
 * 問題を元のファイルに上書き保存する.
 */
- (void)save;

/**
 * 与えられた位置の数字を得る.
 * @param x X座標
 * @param y Y座標
 * @return セルの値、空の場合-1
 */
- (NSInteger)valueOfX:(NSInteger)x andY:(NSInteger)y;

/**
 * 問題を文字形式で出力する.
 */
- (void)dump;

/**
 * 状態の文字列を得る.
 * @return 状態の文字列
 */
- (NSString *)statusString;

/**
 * 解くのに掛かった時間の文字列（XX分、YY分、・・・の形式）を得る.
 * @return 解くのに掛かった時間の文字列
 */
- (NSString *)elapsedTimeString;

- (NSString *)difficultyString;

- (NSString *)evaluationString;

- (void)updateElapsedSecond:(NSInteger)sec;

- (void)addElapsedSecond:(NSInteger)sec;

@end
