//
//  KSLBoard.h
//  SLPlayer
//
//  Created by KO on 13/10/27.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSLEdge;
@class KSLProblem;

#pragma mark - 定数

/**
 * Edgeの状態
 */
typedef enum : NSInteger {
    KSLEdgeStatusUnset = -1,        // 未設定
    KSLEdgeStatusOff = 0,           // 線無し
    KSLEdgeStatusOn = 1             // 線有り
} KSLEdgeStatus;

/**
 * NodeのGate（斜め方向のOnEdgeの通過状態）の状態
 */
typedef enum : NSInteger {
    KSLGateStatusUnset = -1,        // 未設定
    KSLGateStatusClose = 0,         // 不通過
    KSLGateStatusOpen = 1           // 通過
} KSLGateStatus;

/**
 * NodeのGateの方向
 */
typedef enum : NSInteger {
    KSLGateDirLU,                   // 右下から左上へのGate
    KSLGateDirRU                    // 左下から右上へのGate
} KSLGateDir;

/**
 * ループ（一繋がりの辺）の状態
 */
typedef enum : NSInteger {
    KSLLoopError,                   // 1本のループになっていない
    KSLLoopCellError,               // 1本のループだがセルの数値と合致しない
    KSLLoopFinished                 // 1本のループでなおかつ全てのセルの数値を満たしている
} KSLLoopStatus;

#pragma mark - KSLCell

/**
 * Solver用のCellの状態を表すクラス
 */
@interface KSLCell : NSObject

// 中の数値、空の場合は-1
@property (nonatomic, assign) NSInteger number;

// 四周Edgeの中のOnのEdgeの数
@property (nonatomic, assign) NSInteger onCount;

// 四周Edgeの中のOffのEdgeの数
@property (nonatomic, assign) NSInteger offCount;

// 上側Edge
@property (nonatomic, unsafe_unretained) KSLEdge *topEdge;

// 左側Edge
@property (nonatomic, unsafe_unretained) KSLEdge *leftEdge;

// 下側Edge
@property (nonatomic, unsafe_unretained) KSLEdge *bottomEdge;

// 右側Edge
@property (nonatomic, unsafe_unretained) KSLEdge *rightEdge;

/**
 * 指定の数値でCellを初期化する.
 * @param number 中の数値
 * @return Cell
 */
- (id)initWithNumber:(NSInteger)number;

/**
 * 与えられたEdgeの対辺のEdgeを得る.
 * @param edge Edge
 * @return 対辺のEdge
 */
- (KSLEdge *)oppsiteEdgeOfEdge:(KSLEdge *)edge;

/**
 * セルの番号を変更する.（問題作成時のみ使用）
 * @param number 中の数値
 */
- (void)changeNumber:(NSInteger)number;

@end


#pragma mark - KSLNode

/**
 * Solver用のNodeの状態を表すクラス
 */
@interface KSLNode : NSObject

// X座標
@property (nonatomic, readonly) NSInteger x;

// Y座標
@property (nonatomic, readonly) NSInteger y;

// 接続する4本のEdgeの中の状態がOnのEdgeの数
@property (nonatomic, assign) NSInteger onCount;

// 接続する4本のEdgeの中の状態がOffのEdgeの数
@property (nonatomic, assign) NSInteger offCount;

// 自身が連続線の端点の場合の逆側の端点のNode
@property (nonatomic, unsafe_unretained) KSLNode *oppositeNode;

// 上側Edge
@property (nonatomic, unsafe_unretained) KSLEdge *upEdge;

// 左側Edge
@property (nonatomic, unsafe_unretained) KSLEdge *leftEdge;

// 下側Edge
@property (nonatomic, unsafe_unretained) KSLEdge *downEdge;

// 右側Edge
@property (nonatomic, unsafe_unretained) KSLEdge *rightEdge;

/**
 * 指定の位置で初期化したNodeを生成する.
 * @param x X座標
 * @prama y Y座標
 * @return Node
 */
- (id)initWithX:(NSInteger)x andY:(NSInteger)y;

/**
 * 与えられたOnのEdgeに接続するもう1本のOnのEdgeを返す.
 * @param edge 与えられたOnのEdge
 * @return 接続するOnのEdge
 */
- (KSLEdge *)onEdgeConnectToEdge:(KSLEdge *)edge;

/**
 * 指定の方向のGateの状態を返す.
 * @param dir 方向
 * @return Gateの状態
 */
- (KSLGateStatus)gateStatusOfDir:(NSInteger)dir;

/**
 * 指定の方向のGateの状態を、与えられた状態に設定する.
 * @param dir 方向
 * @param status Gateの状態
 */
- (void)setGateStatusOfDir:(NSInteger)dir toStatus:(KSLGateStatus)status;

@end


#pragma mark - KSLEdge

/**
 * Solver用のEdgeを表すクラス
 */
@interface KSLEdge : NSObject

// 状態
@property (nonatomic, assign) KSLEdgeStatus status;

// 水平なEdgeかどうか
@property (nonatomic, readonly) BOOL horizontal;

// 固定されているかどうか（プレイ中のみ使用）
@property (nonatomic, assign) BOOL fixed;

/**
 * 水平かどうかを指定してEdgeを生成する.
 * @param isHorizontal 水平かどうか
 * @return Edge
 */
- (id)initWithHorizontal:(BOOL)isHorizontal;

/**
 * 初期の状態と水平かどうかを指定してEdgeを生成する.
 * @param aStatus 初期の状態
 * @param isHorizontal 水平かどうか
 * @return Edge
 */
- (id)initWithStatus:(KSLEdgeStatus)aStatus andHorizontal:(BOOL)isHorizontal;

/**
 * 与えられたNodeの逆端のNodeを返す.
 * @param node 端部のNode
 * @return 逆端のNode
 */
- (KSLNode *)anotherNodeOfNode:(KSLNode *)node;

/**
 * 指定の方向のCellを返す.
 * @param dir 左右方向（0:インデックスの小さい方、1:インデックスの大きい方）
 * @return Cell
 */
- (KSLCell *)cellOfDir:(NSInteger)dir;

/**
 * 指定の方向のCellを設定する.
 * @param dir 左右方向（0:インデックスの小さい方、1:インデックスの大きい方）
 * @param cell 対象のCell
 */
- (void)setCellOfDir:(NSInteger)dir toCell:(KSLCell *)cell;

/**
 * 指定の方向のNodeを返す.
 * @param lh 前後方向（0:インデックスの小さい方、1:インデックスの大きい方）
 * @return Node
 */
- (KSLNode *)nodeOfLH:(NSInteger)lh;

/**
 * 指定の方向のNodeを設定する.
 * @param lh 前後方向（0:インデックスの小さい方、1:インデックスの大きい方）
 * @param node 対象のNode
 */
- (void)setNodeOfLH:(NSInteger)lh toNode:(KSLNode *)node;

/**
 * 自分の延長上のEdgeを得る.
 * @param lh 前後方向（0:インデックスの小さい方、1:インデックスの大きい方）
 * @return 自分の延長上のEdge
 */
- (KSLEdge *)straightEdgeOfLH:(NSInteger)lh;

/**
 * 自分の延長上のEdgeを設定する.
 * @param lh 前後方向（0:インデックスの小さい方、1:インデックスの大きい方）
 * @param 自分の延長上のEdge
 */
- (void)setStraightEdgeOfLH:(NSInteger)lh toEdge:(KSLEdge *)edge;

@end


#pragma mark - KSLBoard

/**
 * Solver用の盤面を表すクラス.
 */
@interface KSLBoard : NSObject

// 幅（水平方向のCellの数）
@property (nonatomic, readonly) NSInteger width;

// 高さ（鉛直方向のCellの数）
@property (nonatomic, readonly) NSInteger height;

// Cellの配列
@property (nonatomic, readonly) NSMutableArray *cells;

// Nodeの配列
@property (nonatomic, readonly) NSMutableArray *nodes;

// 水平方向Edgeの配列
@property (nonatomic, readonly) NSMutableArray *hEdges;

// 鉛直方向Edgeの配列
@property (nonatomic, readonly) NSMutableArray *vEdges;

/**
 * 与えられた問題で盤面を初期化する.
 * @param problem 問題
 * @return 盤面
 */
- (id)initWithProblem:(KSLProblem *)problem;

/**
 * 指定の位置のCellを返す.
 * @param x X座標
 * @param y Y座標
 * @return その位置のCell
 */
- (KSLCell *)cellAtX:(NSInteger)x andY:(NSInteger)y;

/**
 * 指定の位置のNodeを返す.
 * @param x X座標
 * @param y Y座標
 * @return その位置のNode
 */
- (KSLNode *)nodeAtX:(NSInteger)x andY:(NSInteger)y;

/**
 * 指定の位置の水平方向のEdgeを返す.
 * @param x X座標
 * @param y Y座標
 * @return その位置の水平方向のEdge
 */
- (KSLEdge *)hEdgeAtX:(NSInteger)x andY:(NSInteger)y;

/**
 * 指定の位置の鉛直方向のEdgeを返す.
 * @param x X座標
 * @param y Y座標
 * @return その位置の鉛直方向のEdge
 */
- (KSLEdge *)vEdgeAtX:(NSInteger)x andY:(NSInteger)y;

/**
 * 開いた（onCountが1の）Nodeを返す.
 * @return 最初に見つかった開いたNode
 */
- (KSLNode *)findOpenNode;

/**
 * 分岐用の（onCountが番号-1の）Cellを返す.
 * @return 最初に見つかった分岐用のCell
 */
- (KSLCell *)findCellForBranch;

/**
 * 開いた（onCountが番号より小さい）Cellを返す.
 * @return 最初に見つかった開いたCell
 */
- (KSLCell *)findOpenCell;

/**
 * 状態がOnのEdgeを返す.
 * @return 最初に見つかったOnのEdge
 */
- (KSLEdge *)findOnEdge;

/**
 * 与えられた文字列に対応するEdgeを返す.
 * @param identifier Edgeを示す文字列
 * @return 対応するEdge
 */
- (KSLEdge *)findEdgeWithId:(NSString *)identifier;

/**
 * 与えられたNodeの配列内のインデックスを返す.
 * @param node Node
 * @return 配列内のインデックス
 */
- (NSInteger)nodeIndex:(KSLNode *)node;

/**
 * 指定した斜め方向にいくつかの2のセルの向こうに3のセルが続いている場合にその3のセルを返す.
 * @param cell 対象のCell
 * @param dx 斜めのベクトルの水平方向成分
 * @param dy 斜めのベクトルの鉛直方向成分
 * @return (0〜X個の）連続した2のセルの向こうに3のセルが見つかった場合にその3のセル、見つからなければnil
 */
- (KSLCell *)get3Across2FromCell:(KSLCell *)cell withDx:(NSInteger)dx dy:(NSInteger)dy;

/**
 * 与えれた2つのNodeを結ぶEdgeが存在すればそれを返す.
 * @param node1 Node1
 * @param node2 Node2
 * @return 2つのNodeを結ぶEdge、存在しなければnil
 */
- (KSLEdge *)getJointEdgeOfNodes:(KSLNode *)node1 and:(KSLNode *)node2;

/**
 * 与えられたNodeからEdge方向に発する連続線の末端のNodeを見つける.
 * @param root 根元のNode
 * @param edge 連続線に含まれるEdge
 * @return 連側線のedgeから見てrootと逆側の末端のNode、連続線が閉じている場合にはnil
 */
- (KSLNode *)getLoopEndWithNode:(KSLNode *)root andEdge:(KSLEdge *)edge;

/**
 * 与えられたedgeを含む閉じた連続線が正しい解答になっているかどうかを確かめる.
 * 正しい解答：onEdgeが不足している数字セルがない、onEdgeの数が連続線の中のEdgeの数と一致している
 * @param edge Edge
 * @return 正しい解答かどうか.
 */
- (BOOL)isLoopFinishedOfEdge:(KSLEdge *)edge;

/**
 * 与えられたedgeを含む連続線の状態を得る
 * @param edge Edge
 * @return 連続線の状態
 */
- (KSLLoopStatus)loopStatusOfEdge:(KSLEdge *)edge;

/**
 * 解答の連続線を得る.（正しい解答が得られていることが前提）
 */
- (NSArray *)route;

/**
 * onEdgeの数を得る.
 */
- (NSInteger)countOnEdge;

/**
 * Edgeを固定する（変更を出来なくする）.
 */
- (void)fixStatus;

/**
 * Edgeを全てクリアする.（未設定の状態にする）
 */
- (void)clear;

/**
 * 固定されていないEdgeを全て未設定の状態にする
 */
- (void)erase;

/**
 * 文字で盤面を出力する.
 */
- (void)dump;

/**
 * 与えられた大きさの画像として出力する.
 * @param imageWidth 画像の幅
 * @param imageHeight 画像の高さ
 * @return 盤面を表現する画像
 */
- (UIImage *)createImageWithWidth:(NSInteger)imageWidth andHeight:(NSInteger)imageHeight;

/**
 * 与えられたコンテキストに与えられたパラメータで盤面を描画する.
 * @param context 描画コンテキスト
 * @param origin 問題座標系左上Nodeの画面座標系上での位置
 * @param pitch セルの幅
 * @param rotate 画面が回転しているかどうか
 * @param erasableColor 消去可能な部分の色
 */
- (void)drawImageWithContext:(CGContextRef)context origin:(CGPoint)origin pitch:(CGFloat)pitch
                      rotate:(BOOL)rotate erasableColor:(CGColorRef)erasableColor;

@end

