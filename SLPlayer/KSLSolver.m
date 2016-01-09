//
//  KSLSolver.m
//  SLPlayer
//
//  Created by KO on 13/10/29.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import "KSLSolver.h"
#import "KSLProblem.h"
#import "KSLBoard.h"

#define KSLLOOP_FAILED_EXCEPTION        @"LoopFailedException"
#define KSLLOOP_COMPLETED_EXCEPTION     @"LoopCompletedException"


#pragma mark - KSLBranch

/**
 * ルートが枝分かれ可能な箇所からの個々の分岐を表すクラス.
 */
@interface KSLBranch : NSObject

// 分岐先のEdge
@property (nonatomic, readonly) KSLEdge *edge;

// 分岐位置のNode
@property (nonatomic, readonly) KSLNode *root;

/**
 * 与えられたパラメータの新規の分岐を生成する.
 * @param aRoot
 * @param aEdge
 */
- (id)initWithRoot:(KSLNode *)aRoot andEdge:(KSLEdge *)aEdge;

@end

@implementation KSLBranch

- (id)initWithRoot:(KSLNode *)aRoot andEdge:(KSLEdge *)aEdge
{
    self = [super init];
    if (self) {
        _root = aRoot;
        _edge = aEdge;
    }
    return self;
}

@end


#pragma mark - KSLSolver

@implementation KSLSolver
{
    // シミュレーション時の全ステップを保持している配列
    NSMutableArray *_steps;
    
    // 現在のステップ
    NSMutableArray *_currentStep;
    
    // 現在のステップをクリア中かどうか
    BOOL _clearling;
    
    // 得られたルートの配列
    NSMutableArray *_routes;
    
    // 現在のステップで状態を変更されたEdgeの配列
    NSMutableArray *_changedEdges;
    
    // Edgeの状態が変更されたことにより影響を受けるCellの配列
    NSMutableOrderedSet *affectedCells;
}

#pragma mark - 初期化

- (id)initWithBoard:(KSLBoard *)board
{
    self = [super init];
    if (self) {
        _board = board;
    }
    return self;
}

#pragma mark - 処理

- (BOOL)solveWithError:(NSError **)error
{
    _routes = [NSMutableArray array];
    _steps = [NSMutableArray array];
    _changedEdges = [NSMutableArray array];
    affectedCells = [NSMutableOrderedSet orderedSet];
    
    
    @try {
        [self initCorner];
        [self initZero];
        [self initThree];
        [self checkSurroundingElements];
    }
    @catch (NSException *ex) {
        [_board dump];
        if ([ex.name isEqualToString:KSLLOOP_COMPLETED_EXCEPTION]) {
            [_routes addObject:_board.route];
            return YES;
        }
        *error = [NSError errorWithDomain:@"Solver"
                code:(_routes.count ? KSLSolverErrorMultipleLoops : KSLSolverErrorNoLoop) userInfo:nil];
        return NO;
    }
    
    // 小ループのチェックを通常のチェックに組み入れたところ、TryOneStepを実行する方が
    // 単に分岐して探索するより遅くなったためコメントアウト
    //    [_board dumpWithEdeg:nil];
    //    @try {
    //        while (YES) {
    //            @autoreleasepool {
    //                if (![self _tryOneStep]) {
    //                    break;
    //                }
    //            }
    //        }
    //    }
    //    @catch (NSException *ex) {
    //        if ([ex.name isEqualToString:KSLLOOP_COMPLETED_EXCEPTION]) {
    //            [_routes addObject:_board.route];
    //            return YES;
    //        }
    //        return NO;
    //    }
    
    [_board dump];
    NSArray *branches = nil;
    KSLNode *root = [_board findOpenNode];
    if (root) {
        branches = [self createBranchesFromNode:root];
    } else {
        KSLCell *cell = [_board findCellForBranch];
        if (cell) {
            branches = [self createBranchesFromCell:cell];
        }
    }
    
    if (branches) {
        [self tryBranches:[branches mutableCopy]];
    }
    if (_routes.count == 1) {
        return YES;
    }
    *error = [NSError errorWithDomain:@"Solver"
                code:(_routes.count ? KSLSolverErrorMultipleLoops : KSLSolverErrorNoLoop) userInfo:nil];
    return NO;
}

#pragma mark - プロパティ

- (NSArray *)route
{
    if (_routes.count == 1) {
        return [_routes lastObject];
    } else {
        return nil;
    }
}

#pragma mark - プライベートメッソド（初期チェック)

/**
 * 角の数字により確定する辺を設定する.
 */
- (void)initCorner
{
    [self initCornerWithHDir:0 andVDir:0];
    [self initCornerWithHDir:0 andVDir:1];
    [self initCornerWithHDir:1 andVDir:0];
    [self initCornerWithHDir:1 andVDir:1];
}

/**
 * 指定の位置の角の数字により確定する辺を設定する.
 * @param hdir 水平方向位置（0:左側、1:右側）
 * @param vdir 鉛直方向位置（0:上側、1:下側）
 */
- (void)initCornerWithHDir:(NSInteger)hdir andVDir:(NSInteger)vdir
{
    NSInteger x = hdir ? _board.width - 1 : 0;
    NSInteger y = vdir ? _board.height - 1 : 0;
    NSInteger dx = hdir ? -1 : 1;
    NSInteger dy = vdir ? -1 : 1;
    
    switch ([_board cellAtX:x andY:y].number) {
        case 1:
            [self changeEdge:[_board vEdgeAtX:x+hdir andY:y] status:KSLEdgeStatusOff];
            [self changeEdge:[_board hEdgeAtX:x andY:y+vdir] status:KSLEdgeStatusOff];
            break;
        case 2:
            [self changeEdge:[_board vEdgeAtX:x+hdir andY:y+dy] status:KSLEdgeStatusOn];
            [self changeEdge:[_board hEdgeAtX:x+dx andY:y+vdir] status:KSLEdgeStatusOn];
            if ([_board cellAtX:x+dx andY:y].number == 3) {
                [self changeEdge:[_board vEdgeAtX:x+hdir+dx+dx andY:y] status:KSLEdgeStatusOn];
            }
            if ([_board cellAtX:x andY:y+dy].number == 3) {
                [self changeEdge:[_board hEdgeAtX:x andY:y+vdir+dy+dy] status:KSLEdgeStatusOn];
            }
            break;
        case 3:
            [self changeEdge:[_board vEdgeAtX:x+hdir andY:y] status:KSLEdgeStatusOn];
            [self changeEdge:[_board hEdgeAtX:x andY:y+vdir] status:KSLEdgeStatusOn];
            break;
    }
}

/**
 * 0により確定する辺を設定する.
 */
- (void)initZero
{
    for (NSInteger y = 0; y < _board.height; y++) {
        for (NSInteger x = 0; x < _board.width; x++) {
            KSLCell *cell = [_board cellAtX:x andY:y];
            if (cell.number == 0) {
                [self changeEdge:cell.topEdge status:KSLEdgeStatusOff];
                [self changeEdge:cell.leftEdge status:KSLEdgeStatusOff];
                [self changeEdge:cell.bottomEdge status:KSLEdgeStatusOff];
                [self changeEdge:cell.rightEdge status:KSLEdgeStatusOff];
            }
        }
    }
}

/**
 * 3と周辺の数字により確定する辺を設定する.
 */
- (void)initThree
{
    for (NSInteger y = 0; y < _board.height; y++) {
        for (NSInteger x = 0; x < _board.width; x++) {
            KSLCell *cell = [_board cellAtX:x andY:y];
            if (cell.number == 3) {
                if (x < _board.width - 1) {
                    KSLCell *aCell = [cell.rightEdge cellOfDir:1];
                    if (aCell.number == 3) {
                        [self changeEdge:cell.leftEdge status:KSLEdgeStatusOn];
                        [self changeEdge:cell.rightEdge status:KSLEdgeStatusOn];
                        [self changeEdge:aCell.rightEdge status:KSLEdgeStatusOn];
                        if (y > 0) {
                            [self changeEdge:[cell.rightEdge straightEdgeOfLH:0] status:KSLEdgeStatusOff];
                            if ([cell.topEdge cellOfDir:0].number == 2) {
                                [self changeEdge:[cell.topEdge cellOfDir:0].topEdge status:KSLEdgeStatusOn];
                                if (x > 0) {
                                    [self changeEdge:[cell.topEdge straightEdgeOfLH:0] status:KSLEdgeStatusOff];
                                }
                            }
                            if ([aCell.topEdge cellOfDir:0].number == 2) {
                                [self changeEdge:[aCell.topEdge cellOfDir:0].topEdge status:KSLEdgeStatusOn];
                                if (x < _board.width - 2) {
                                    [self changeEdge:[aCell.topEdge straightEdgeOfLH:1] status:KSLEdgeStatusOff];
                                }
                            }
                        }
                        if (y < _board.height - 1) {
                            [self changeEdge:[cell.rightEdge straightEdgeOfLH:1] status:KSLEdgeStatusOff];
                            if ([cell.bottomEdge cellOfDir:1].number == 2) {
                                [self changeEdge:[cell.bottomEdge cellOfDir:1].bottomEdge status:KSLEdgeStatusOn];
                                if (x > 0) {
                                    [self changeEdge:[cell.bottomEdge straightEdgeOfLH:0] status:KSLEdgeStatusOff];
                                }
                            }
                            if ([aCell.bottomEdge cellOfDir:1].number == 2) {
                                [self changeEdge:[aCell.bottomEdge cellOfDir:1].bottomEdge status:KSLEdgeStatusOn];
                                if (x < _board.width - 2) {
                                    [self changeEdge:[aCell.bottomEdge straightEdgeOfLH:1] status:KSLEdgeStatusOff];
                                }
                            }
                        }
                    }
                    aCell = [_board get3Across2FromCell:cell withDx:1 dy:-1];
                    if (aCell) {
                        [self changeEdge:cell.bottomEdge status:KSLEdgeStatusOn];
                        [self changeEdge:cell.leftEdge status:KSLEdgeStatusOn];
                        [self changeEdge:aCell.topEdge status:KSLEdgeStatusOn];
                        [self changeEdge:aCell.rightEdge status:KSLEdgeStatusOn];
                    }
                    aCell = [_board get3Across2FromCell:cell withDx:1 dy:1];
                    if (aCell) {
                        [self changeEdge:cell.topEdge status:KSLEdgeStatusOn];
                        [self changeEdge:cell.leftEdge status:KSLEdgeStatusOn];
                        [self changeEdge:aCell.bottomEdge status:KSLEdgeStatusOn];
                        [self changeEdge:aCell.rightEdge status:KSLEdgeStatusOn];
                    }
                }
                if (y > 0) {
                    KSLCell *aCell = [cell.topEdge cellOfDir:0];
                    if (aCell.number == 3) {
                        [self changeEdge:cell.bottomEdge status:KSLEdgeStatusOn];
                        [self changeEdge:cell.topEdge status:KSLEdgeStatusOn];
                        [self changeEdge:aCell.topEdge status:KSLEdgeStatusOn];
                        if (x > 0) {
                            [self changeEdge:[cell.topEdge straightEdgeOfLH:0] status:KSLEdgeStatusOff];
                            if ([cell.leftEdge cellOfDir:0].number == 2) {
                                [self changeEdge:[cell.leftEdge cellOfDir:0].leftEdge status:KSLEdgeStatusOn];
                                if (y < _board.height - 1) {
                                    [self changeEdge:[cell.leftEdge straightEdgeOfLH:1] status:KSLEdgeStatusOff];
                                }
                            }
                            if ([aCell.leftEdge cellOfDir:0].number == 2) {
                                [self changeEdge:[aCell.leftEdge cellOfDir:0].leftEdge status:KSLEdgeStatusOn];
                                if (y > 1) {
                                    [self changeEdge:[aCell.leftEdge straightEdgeOfLH:0] status:KSLEdgeStatusOff];
                                }
                            }
                        }
                        if (x < _board.width - 1) {
                            [self changeEdge:[cell.topEdge straightEdgeOfLH:1] status:KSLEdgeStatusOff];
                            if ([cell.rightEdge cellOfDir:1].number == 2) {
                                [self changeEdge:[cell.rightEdge cellOfDir:1].rightEdge status:KSLEdgeStatusOn];
                                if (y < _board.height - 1) {
                                    [self changeEdge:[cell.rightEdge straightEdgeOfLH:1] status:KSLEdgeStatusOff];
                                }
                            }
                            if ([aCell.rightEdge cellOfDir:1].number == 2) {
                                [self changeEdge:[aCell.rightEdge cellOfDir:1].rightEdge status:KSLEdgeStatusOn];
                                if (y > 1) {
                                    [self changeEdge:[aCell.rightEdge straightEdgeOfLH:0] status:KSLEdgeStatusOff];
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

/**
 * 外周の数字で確定する辺を設定する.
 */
- (void)initBorder
{
    [self initVBorderWithHDir:0];
    [self initVBorderWithHDir:1];
    [self initHBorderWithVDir:0];
    [self initHBorderWithVDir:1];
}

/**
 * 左右の外周の数字で確定する辺を設定する.
 * @param hdir 水平方向位置（0:左側、1:右側）
 */
- (void)initVBorderWithHDir:(NSInteger)hdir
{
    NSInteger x = hdir ? _board.width - 1 : 0;
    
    for (NSInteger y = 1; y < _board.height - 1; y++) {
        KSLCell *cell = [_board cellAtX:x andY:y];
        if (cell.number == 1) {
            KSLCell *aCell = [_board cellAtX:x andY:y-1];
            if (aCell.number == 1) {
                [self changeEdge:cell.topEdge status:KSLEdgeStatusOff];
            } else if (aCell.number == 3) {
                [self changeEdge:[_board vEdgeAtX:x+hdir andY:y-1] status:KSLEdgeStatusOn];
                [self changeEdge:[_board vEdgeAtX:x+1-hdir andY:y] status:KSLEdgeStatusOff];
                [self changeEdge:cell.bottomEdge status:KSLEdgeStatusOff];
            }
            aCell = [_board cellAtX:x andY:y+1];
            if (aCell.number == 3) {
                [self changeEdge:[_board vEdgeAtX:x+hdir andY:y+1] status:KSLEdgeStatusOn];
                [self changeEdge:[_board vEdgeAtX:x+1-hdir andY:y] status:KSLEdgeStatusOff];
                [self changeEdge:cell.topEdge status:KSLEdgeStatusOff];
            }
        }
    }
}

/**
 * 上下の外周の数字で確定する辺を設定する.
 * @param vdir 鉛直方向位置（0:上側、1:下側）
 */
- (void)initHBorderWithVDir:(NSInteger)vdir
{
    NSInteger y = vdir ? _board.height - 1 : 0;
    
    for (NSInteger x = 1; x < _board.width - 1; x++) {
        KSLCell *cell = [_board cellAtX:x andY:y];
        if (cell.number == 1) {
            KSLCell *aCell = [_board cellAtX:x-1 andY:y];
            if (aCell.number == 1) {
                [self changeEdge:cell.leftEdge status:KSLEdgeStatusOff];
            } else if (aCell.number == 3) {
                [self changeEdge:[_board hEdgeAtX:x-1 andY:y+vdir] status:KSLEdgeStatusOn];
                [self changeEdge:[_board hEdgeAtX:x andY:y+1-vdir] status:KSLEdgeStatusOff];
                [self changeEdge:cell.rightEdge status:KSLEdgeStatusOff];
            }
            aCell = [_board cellAtX:x+1 andY:y];
            if (aCell.number == 3) {
                [self changeEdge:[_board hEdgeAtX:x+1 andY:y+vdir] status:KSLEdgeStatusOn];
                [self changeEdge:[_board hEdgeAtX:x andY:y+1-vdir] status:KSLEdgeStatusOff];
                [self changeEdge:cell.leftEdge status:KSLEdgeStatusOff];
            }
        }
    }
}

#pragma mark - プライベートメッソド（ステップの実行)

/**
 * 試しに1ステップだけ既存の連続線の末端の未設定のEdgeをOnまたはOffに設定して、エラーになればその逆の状態に確定させる.
 * ステップ：1つの辺をOnまたはOffに設定し、それにより影響を受ける各種の状態変更を連鎖的に行う一連の処理.
 */
- (BOOL)tryOneStep
{
    [self startNewStep];
    for (NSInteger y = 0; y <= _board.height; y++) {
        for (NSInteger x = 0; x <= _board.width; x++) {
            KSLNode *node = [_board nodeAtX:x andY:y];
            if (node.onCount == 1) {
                NSArray *branches = [self createBranchesFromNode:node];
                for (NSInteger b = 0; b < branches.count; b++) {
                    KSLBranch *branch = branches[b];
                    if ([self tryWithEdge:branch.edge withStatus:KSLEdgeStatusOn]) {
                        return YES;
                    }
                    if ([self tryWithEdge:branch.edge withStatus:KSLEdgeStatusOff]) {
                        return YES;
                    }
                }
            }
        }
    }
    [self removeCurrentStep];
    return NO;
}

/**
 * 試しに1ステップだけ与えられたEdgeを指定の状態に設定し、エラーになった場合は逆の状態に確定する.
 * @param edge 対象のEdge
 * @param status 状態（KSLEdgeStatusOnまたはKSLEdgeStatusOff）
 * @return 指定のEdgeの状態が確定したかどうか.
 */
- (BOOL)tryWithEdge:(KSLEdge *)edge withStatus:(KSLEdgeStatus)status
{
    @try {
        [_changedEdges removeAllObjects];
        [affectedCells removeAllObjects];
        [self changeEdge:edge status:status];
        [self checkSurroundingElements];
    }
    @catch (NSException *ex) {
        if ([ex.name isEqualToString:KSLLOOP_COMPLETED_EXCEPTION]) {
            // skip.
        } else if ([ex.name isEqualToString:KSLLOOP_FAILED_EXCEPTION]) {
            KSLEdgeStatus anotherStatus = status == KSLEdgeStatusOn ? KSLEdgeStatusOff : KSLEdgeStatusOn;
            [self removeCurrentStep];
            [_changedEdges removeAllObjects];
            [affectedCells removeAllObjects];
            [self changeEdge:edge status:anotherStatus];
            [self checkSurroundingElements];
            return YES;
        } else {
            [ex raise];
        }
    }
    [self clearCurrentStep];
    return NO;
}

/**
 * 与えられたNodeから発生する分岐の配列を得る.
 * @param root 分岐の起点
 * @return 分岐の枝の配列
 */
- (NSArray *)createBranchesFromNode:(KSLNode *)root
{
    NSMutableArray *branches = [NSMutableArray array];
    if (root.upEdge.status == KSLEdgeStatusUnset) {
        [branches addObject:[[KSLBranch alloc] initWithRoot:root andEdge:root.upEdge]];
    }
    if (root.leftEdge.status == KSLEdgeStatusUnset) {
        [branches addObject:[[KSLBranch alloc] initWithRoot:root andEdge:root.leftEdge]];
    }
    if (root.downEdge.status == KSLEdgeStatusUnset) {
        [branches addObject:[[KSLBranch alloc] initWithRoot:root andEdge:root.downEdge]];
    }
    if (root.rightEdge.status == KSLEdgeStatusUnset) {
        [branches addObject:[[KSLBranch alloc] initWithRoot:root andEdge:root.rightEdge]];
    }
    return branches;
}

/**
 * 与えられたCeeの周囲から発生する分岐の配列を得る.
 * @param cell 対象のCell（後1辺だけOnの辺が不足しているCell）
 * @return 分岐の枝の配列
 */
- (NSArray *)createBranchesFromCell:(KSLCell *)cell
{
    NSMutableArray *branches = [NSMutableArray array];
    if (cell.topEdge.status == KSLEdgeStatusUnset) {
        [branches addObject:[[KSLBranch alloc] initWithRoot:[cell.topEdge nodeOfLH:0]
                                                    andEdge:cell.topEdge]];
    }
    if (cell.leftEdge.status == KSLEdgeStatusUnset) {
        [branches addObject:[[KSLBranch alloc] initWithRoot:[cell.leftEdge nodeOfLH:0]
                                                    andEdge:cell.leftEdge]];
    }
    if (cell.bottomEdge.status == KSLEdgeStatusUnset) {
        [branches addObject:[[KSLBranch alloc] initWithRoot:[cell.bottomEdge nodeOfLH:0]
                                                    andEdge:cell.bottomEdge]];
    }
    if (cell.rightEdge.status == KSLEdgeStatusUnset) {
        [branches addObject:[[KSLBranch alloc] initWithRoot:[cell.rightEdge nodeOfLH:0]
                                                    andEdge:cell.rightEdge]];
    }
    return branches;
}

/**
 * 与えられた分岐のリストを順番にKSLEdgeStatusOnにして試す.
 * 分岐の枝の状態を変えてもルートが確定しなかった場合、その先の末端で再起的に処理を行う.
 * 効率化のため実際には再起呼び出しは行わずループで処理する.
 * @param branches 分岐の枝の配列
 */
- (void)tryBranches:(NSMutableArray *)branches
{
    NSMutableArray *branchStack = [NSMutableArray arrayWithObject:branches];
    NSInteger level = 1;
    while (level) {
        @autoreleasepool {
            if (_steps.count == level - 1) {
                // 新しいステップの開始
                [self startNewStep];
            } else {
                // 深い部分の探索から戻ってきた状態
                [self clearCurrentStep];
            }
            branches = [branchStack lastObject];
            BOOL addDepth = NO;
            while (branches.count) {
                KSLBranch *branch = branches[0];
                [branches removeObjectAtIndex:0];
                @try {
                    printf("LEVEL%2ld BRANCH:%s.%s ", (long)level,
                           branch.root.description.UTF8String, branch.edge.description.UTF8String);
                    [_changedEdges removeAllObjects];
                    [affectedCells removeAllObjects];
                    [self changeEdge:branch.edge status:KSLEdgeStatusOn];
                    [self checkSurroundingElements];
                }
                @catch (NSException *ex) {
                    KSLEdge *edge = ex.userInfo[@"edge"];
                    if ([ex.name isEqualToString:KSLLOOP_COMPLETED_EXCEPTION]) {
                        [_routes addObject:_board.route];
                        printf("SUCCESS\n");
                    } else if ([ex.name isEqualToString:KSLLOOP_FAILED_EXCEPTION]) {
                        printf("FAILURE:%s\n", edge.description.UTF8String);
                    } else {
                        [ex raise];
                    }
                    //[_board dump];
                    //[self dumpStepsFromIndex:1];
                    [self clearCurrentStep];
                    continue;
                }
                printf("\n");
                KSLNode *newRoot = [_board getLoopEndWithNode:branch.root andEdge:branch.edge];
                NSArray *newBranches = [self createBranchesFromNode:newRoot];
                [branchStack addObject:newBranches];
                level++;
                addDepth = YES;
                break;
            }
            if (!addDepth) {
                [self removeCurrentStep];
                [branchStack removeLastObject];
                level--;
            }
        }
    }
}

/**
 * 新しいステップを開始する準備を行う.
 */
- (void)startNewStep
{
    _currentStep = [NSMutableArray array];
    [_steps addObject:_currentStep];
}

/**
 * 現在処理中のステップで行った処理を全て元に戻す.
 */
- (void)clearCurrentStep
{
    _clearling = YES;
    
    for (NSInteger i = _currentStep.count - 1; i >= 0; i--) {
        KSLAction *action = _currentStep[i];
        KSLEdge *edge = nil;
        KSLNode *node = nil;
        switch (action.type) {
            case KSLActionTypeEdgeStatus:
                edge = action.target;
                edge.status = action.oldValue;
                break;
                
            case KSLActionTypeOppositeNode:
                node = action.target;
                node.oppositeNode = action.oldValue < 0 ? nil : _board.nodes[action.oldValue];
                break;
                
            case KSLActionTypeLUGateStatus:
                node = action.target;
                [node setGateStatusOfDir:KSLGateDirLU toStatus:action.oldValue];
                break;
                
            case KSLActionTypeRUGateStatus:
                node = action.target;
                [node setGateStatusOfDir:KSLGateDirRU toStatus:action.oldValue];
                break;
                
            default:
                break;
        }
    }
    [_currentStep removeAllObjects];
    
    _clearling = NO;
}

/**
 * 現在のステップを削除し、一つ前のステップをカレントにする.
 */
- (void)removeCurrentStep
{
    [self clearCurrentStep];
    [_steps removeLastObject];
    
    _currentStep = _steps.lastObject;
}


#pragma mark - プライベートメッソド（状態の変更)

/**
 * Edgeの状態を与えられた状態に変更する.
 * 周辺のNodeやCellの状態から、許容されない状態へ変更した場合には例外が発生する.
 * 変更の結果ループが発生した場合には、その状態そのループの状態をチェックする.（例外を発生させる）
 * また自分が所属する連続線の末端同士が隣り合う状態になった場合には、その辺を閉じることで出来るループをチェックし、
 * 正常なループが出来る場合には辺の状態をOnに変更した上で例外を発生させ、小ループが出来る場合にはその辺の状態をOffに変更する.
 * @param edge 対象のEdge
 * @param status 新しい状態
 * @throws LoopCompletedException 正しいループが完成した場合
 *         LoopFailureException 不整合が発生した場合、不完全なループが発生した場合
 *         以下、このメソッドを呼ぶ全てのメソッドで同じExceptionがthrowされる可能性がある.
 */
- (void)changeEdge:(KSLEdge *)edge status:(KSLEdgeStatus)status
{
    if (edge.status == status) return;
    
    if (edge.status != KSLEdgeStatusUnset) {
        [[NSException exceptionWithName:KSLLOOP_FAILED_EXCEPTION
                                 reason:nil userInfo:@{@"edge":edge}] raise];
    }
    if (status == KSLEdgeStatusOn) {
        // ノードのOnの変数が2より大きくなってしまったらエラー
        if ([edge nodeOfLH:0].onCount == 2 || [edge nodeOfLH:1].onCount == 2) {
            [[NSException exceptionWithName:KSLLOOP_FAILED_EXCEPTION
                                     reason:nil userInfo:@{@"edge":edge}] raise];
        }
        
        // セルのOnの辺数がナンバーより大きくなってしまったらエラー
        KSLCell *cell = [edge cellOfDir:0];
        if (cell.onCount == cell.number) {
            [[NSException exceptionWithName:KSLLOOP_FAILED_EXCEPTION
                                     reason:nil userInfo:@{@"edge":edge}] raise];
        }
        cell = [edge cellOfDir:1];
        if (cell.onCount == cell.number) {
            [[NSException exceptionWithName:KSLLOOP_FAILED_EXCEPTION
                                     reason:nil userInfo:@{@"edge":edge}] raise];
        }
    } else if (status == KSLEdgeStatusOff) {
        // セルのOffの辺数が(4-ナンバー)より大きくなってしまったらエラー
        KSLCell *cell = [edge cellOfDir:0];
        if (cell.number >= 0 && cell.offCount == 4 - cell.number) {
            [[NSException exceptionWithName:KSLLOOP_FAILED_EXCEPTION
                                     reason:nil userInfo:@{@"edge":edge}] raise];
        }
        cell = [edge cellOfDir:1];
        if (cell.number >= 0 && cell.offCount == 4 - cell.number) {
            [[NSException exceptionWithName:KSLLOOP_FAILED_EXCEPTION
                                     reason:nil userInfo:@{@"edge":edge}] raise];
        }
    }
    
    KSLEdgeStatus oldStatus = edge.status;
    edge.status = status;
    if (_currentStep) {
        [_currentStep addObject:[[KSLAction alloc] initWithType:KSLActionTypeEdgeStatus
                                                     target:edge fromValue:oldStatus toValue:status]];
    }
    [_changedEdges addObject:edge];
    
    if (status == KSLEdgeStatusOn) {
        // 連続線の端部の更新
        KSLNode *head = [edge nodeOfLH:0].oppositeNode ? [edge nodeOfLH:0].oppositeNode : [edge nodeOfLH:0];
        KSLNode *tail = [edge nodeOfLH:1].oppositeNode ? [edge nodeOfLH:1].oppositeNode : [edge nodeOfLH:1];
        
        if (head == [edge nodeOfLH:1]) {
            [self checkNewLoopWithEdge:edge];
        } else {
            if (_currentStep) {
                [_currentStep addObject:[[KSLAction alloc]
                                     initWithType:KSLActionTypeOppositeNode
                                     target:head fromValue:[_board nodeIndex:head.oppositeNode]
                                     toValue:[_board nodeIndex:tail]]];
                [_currentStep addObject:[[KSLAction alloc]
                                     initWithType:KSLActionTypeOppositeNode
                                     target:tail fromValue:[_board nodeIndex:tail.oppositeNode]
                                     toValue:[_board nodeIndex:head]]];
            }
            head.oppositeNode = tail;
            tail.oppositeNode = head;
            
            KSLEdge *jointEdge = [_board getJointEdgeOfNodes:head and:tail];
            if (jointEdge && jointEdge.status == KSLGateStatusUnset) {
                // headとtailが隣り合っている場合
                @try {
                    jointEdge.status = KSLEdgeStatusOn;
                    if (_currentStep) {
                        [_currentStep addObject:[[KSLAction alloc] initWithType:KSLActionTypeEdgeStatus
                                                    target:jointEdge fromValue:KSLEdgeStatusUnset toValue:KSLEdgeStatusOn]];
                    }
                    [self checkNewLoopWithEdge:jointEdge];
                }
                @catch (NSException *ex) {
                    jointEdge.status = KSLEdgeStatusUnset;
                    if (_currentStep) {
                        [_currentStep removeLastObject];
                    }
                    
                    if ([ex.name isEqualToString:KSLLOOP_COMPLETED_EXCEPTION]) {
                        //[ex raise];
                        // このノードでの分岐の処理が行われなくなってしまうため、正式な手続きで完成するまで待つ
                    } else {
                        [self changeEdge:jointEdge status:KSLEdgeStatusOff];
                    }
                }
            }
        }
    }
}

/**
 * 与えられたEdgeで新たなループが発生した際に、その問題が完成しているかを確認しその結果を元に例外を投げる.
 * @param edge 対象のEdge
 * @throws LoopCompletedException 完成した場合
 *         LoopFailureException 不完全な部分がある場合
 */
- (void)checkNewLoopWithEdge:(KSLEdge *)edge
{
    if ([_board isLoopFinishedOfEdge:edge]) {
    // debug用
    //        UIImage *image = [_board createImageWithWidth:400 andHeight:748];
    //        NSData *data = UIImagePNGRepresentation(image);
    //        if ([data writeToFile:@"/Users/zak/route.png" atomically:YES]) {
    //            NSLog(@"ok");
    //        } else {
    //            NSLog(@"ng");
    //        }
        [[NSException exceptionWithName:KSLLOOP_COMPLETED_EXCEPTION
                                 reason:nil userInfo:nil] raise];
    } else {
        [[NSException exceptionWithName:KSLLOOP_FAILED_EXCEPTION
                                 reason:nil userInfo:@{@"edge":edge}] raise];
    }
}

/**
 * 状態を変更されたEdgeに対してその前後のNode、左右のCellに対して直接の影響をチェックする.
 * 更に斜め前方、左右、斜め後方のCellをコーナーチェックの対象として登録する.
 * 全Edgeの周辺チェック終了後、登録されたCellのコーナーチェックを行い、その結果いずれかのEdgeの状態が変更されると、
 * Edge周辺のチェックから繰り返す.
 */
- (void)checkSurroundingElements
{
    while (_changedEdges.count || affectedCells.count) {
        while (_changedEdges.count) {
            KSLEdge *edge = _changedEdges[0];
            [_changedEdges removeObjectAtIndex:0];
            
            switch (edge.status) {
                case KSLEdgeStatusOn:
                    [self checkNodeWithOnEdge:edge ofLH:0];
                    [self checkNodeWithOnEdge:edge ofLH:1];
                    
                    [self checkCellWithOnEdge:edge ofDir:0];
                    [self checkCellWithOnEdge:edge ofDir:1];
                    break;
                case KSLEdgeStatusOff:
                    [self checkNodeWithOffEdge:edge ofLH:0];
                    [self checkNodeWithOffEdge:edge ofLH:1];
                    
                    [self checkCellWithOffEdge:edge ofDir:0];
                    [self checkCellWithOffEdge:edge ofDir:1];
                    break;
                default:
                    break;
            }
            
            [affectedCells addObject:[edge cellOfDir:0]];
            [affectedCells addObject:[edge cellOfDir:1]];
            [affectedCells addObject:[[edge straightEdgeOfLH:0] cellOfDir:0]];
            [affectedCells addObject:[[edge straightEdgeOfLH:0] cellOfDir:1]];
            [affectedCells addObject:[[edge straightEdgeOfLH:1] cellOfDir:0]];
            [affectedCells addObject:[[edge straightEdgeOfLH:1] cellOfDir:1]];
        }
        
        if (affectedCells.count) {
            KSLCell *cell = affectedCells[0];
            [affectedCells removeObjectAtIndex:0];
            [self checkAffectedCell:cell];
        }
    }
}

/**
 * 与えられた状態がOnに変化したEdgeの与えられた方向のNodeをチェックする.
 * @param edge 状態がOnに変化したEdge
 * @param lh 前後(0:indexが小さな側、1:indexが大きな側）
 */
- (void)checkNodeWithOnEdge:(KSLEdge *)edge ofLH:(NSInteger)lh
{
    KSLNode *node = [edge nodeOfLH:lh];
    
    // ノードのOnの辺数が2になったら残りはOff
    if (node.onCount == 2) {
        if (node.upEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:node.upEdge status:KSLEdgeStatusOff];
        }
        if (node.leftEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:node.leftEdge status:KSLEdgeStatusOff];
        }
        if (node.downEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:node.downEdge status:KSLEdgeStatusOff];
        }
        if (node.rightEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:node.rightEdge status:KSLEdgeStatusOff];
        }
    }
    
    // ノードのOffの辺数が2(Onは1)になったら残りはOn
    else if (node.offCount == 2) {
        if (node.upEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:node.upEdge status:KSLEdgeStatusOn];
        }
        if (node.leftEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:node.leftEdge status:KSLEdgeStatusOn];
        }
        if (node.downEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:node.downEdge status:KSLEdgeStatusOn];
        }
        if (node.rightEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:node.rightEdge status:KSLEdgeStatusOn];
        }
    }
}

/**
 * 与えられた状態がOnに変化したEdgeの与えられた方向のCellをチェックする.
 * @param edge 状態がOnに変化したEdge
 * @param dir 左右(0:indexが小さな側、1:indexが大きな側）
 */
- (void)checkCellWithOnEdge:(KSLEdge *)edge ofDir:(NSInteger)dir
{
    KSLCell *cell = [edge cellOfDir:dir];
    
    // セルのOnの辺数がナンバーと一致したら残りはOff
    if (cell.onCount == cell.number) {
        if (cell.topEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:cell.topEdge status:KSLEdgeStatusOff];
        }
        if (cell.leftEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:cell.leftEdge status:KSLEdgeStatusOff];
        }
        if (cell.bottomEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:cell.bottomEdge status:KSLEdgeStatusOff];
        }
        if (cell.rightEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:cell.rightEdge status:KSLEdgeStatusOff];
        }
    }
}

/**
 * 与えられた状態がOffに変化したEdgeの与えられた方向のNodeをチェックする.
 * @param edge 状態がOffに変化したEdge
 * @param lh 前後(0:indexが小さな側、1:indexが大きな側）
 */
- (void)checkNodeWithOffEdge:(KSLEdge *)edge ofLH:(NSInteger)lh
{
    KSLNode *node = [edge nodeOfLH:lh];
    
    // ノードのOffの辺数が3になったら残りもOff
    if (node.offCount == 3) {
        if (node.upEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:node.upEdge status:KSLEdgeStatusOff];
        }
        if (node.leftEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:node.leftEdge status:KSLEdgeStatusOff];
        }
        if (node.downEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:node.downEdge status:KSLEdgeStatusOff];
        }
        if (node.rightEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:node.rightEdge status:KSLEdgeStatusOff];
        }
    }
    
    // ノードのOnの辺数が1でOffの辺数が2になったら残りはOn
    else if (node.offCount == 2 && node.onCount == 1) {
        if (node.upEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:node.upEdge status:KSLEdgeStatusOn];
        }
        if (node.leftEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:node.leftEdge status:KSLEdgeStatusOn];
        }
        if (node.downEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:node.downEdge status:KSLEdgeStatusOn];
        }
        if (node.rightEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:node.rightEdge status:KSLEdgeStatusOn];
        }
    }
    
    // 斜め前(後)方の２つのセルの組み合せ
    KSLEdge *straight = [edge straightEdgeOfLH:lh];
    KSLCell *cell0 = [straight cellOfDir:0];
    KSLCell *cell1 = [straight cellOfDir:1];
    KSLEdge *onEdge;
    KSLEdge *offEdge;
    KSLEdge *offvEdge;
    if (cell0.number == 1 && cell1.number == 1) {
        // 両方が1なら間のEdgeはOff
        [self changeEdge:straight status:KSLEdgeStatusOff];
    } else if (cell0.number == 1 && cell1.number == 3) {
        // 1と3の組み合せなら3の底辺がOn、1の対辺がOff
        if (edge.horizontal) {
            onEdge = lh ? cell1.leftEdge : cell1.rightEdge;
            offEdge = lh ? cell0.rightEdge : cell0.leftEdge;
            offvEdge = cell0.topEdge;
        } else {
            onEdge = lh ? cell1.topEdge : cell1.bottomEdge;
            offEdge = lh ? cell0.bottomEdge : cell0.topEdge;
            offvEdge = cell0.leftEdge;
        }
        [self changeEdge:onEdge status:KSLEdgeStatusOn];
        [self changeEdge:offEdge status:KSLEdgeStatusOff];
        [self changeEdge:offvEdge status:KSLEdgeStatusOff];
    } else if (cell0.number == 3 && cell1.number == 1) {
        if (edge.horizontal) {
            onEdge = lh ? cell0.leftEdge : cell0.rightEdge;
            offEdge = lh ? cell1.rightEdge : cell1.leftEdge;
            offvEdge = cell1.bottomEdge;
        } else {
            onEdge = lh ? cell0.topEdge : cell0.bottomEdge;
            offEdge = lh ? cell1.bottomEdge : cell1.topEdge;
            offvEdge = cell1.rightEdge;
        }
        [self changeEdge:onEdge status:KSLEdgeStatusOn];
        [self changeEdge:offEdge status:KSLEdgeStatusOff];
        [self changeEdge:offvEdge status:KSLEdgeStatusOff];
    }
}

/**
 * 与えられた状態がOffに変化したEdgeの与えられた方向のCellをチェックする.
 * @param edge 状態がOffに変化したEdge
 * @param dir 左右(0:indexが小さな側、1:indexが大きな側）
 */
- (void)checkCellWithOffEdge:(KSLEdge *)edge ofDir:(NSInteger)dir
{
    KSLCell *cell = [edge cellOfDir:dir];
    
    // セルのOffの辺数が(4-ナンバー)と一致したら残りはOn
    if (cell.number > 0 && cell.offCount == 4 - cell.number) {
        if (cell.topEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:cell.topEdge status:KSLEdgeStatusOn];
        }
        if (cell.leftEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:cell.leftEdge status:KSLEdgeStatusOn];
        }
        if (cell.bottomEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:cell.bottomEdge status:KSLEdgeStatusOn];
        }
        if (cell.rightEdge.status == KSLEdgeStatusUnset) {
            [self changeEdge:cell.rightEdge status:KSLEdgeStatusOn];
        }
    }
    
    // セルが2でその向こうが3なら3の一番奥の辺はOn
    if (cell.number == 2) {
        KSLEdge *oedge = [cell oppsiteEdgeOfEdge:edge];
        KSLCell *aCell = [oedge cellOfDir:dir];
        if (aCell.number == 3) {
            [self changeEdge:[aCell oppsiteEdgeOfEdge:oedge] status:KSLEdgeStatusOn];
        }
    }
}

/**
 * 与えられたCellの四隅の斜めに接するCellとの関係のチェックを行う.
 * @param cell 対象のCell
 */
- (void)checkAffectedCell:(KSLCell *)cell
{
    switch (cell.number) {
        case 1:
            for (NSInteger h = 0; h < 2; h++) {
                for (NSInteger v = 0; v < 2; v++) {
                    [self checkAffectedCell1:cell cornerH:h andV:v];
                }
            }
            break;
            
        case 2:
            for (NSInteger h = 0; h < 2; h++) {
                for (NSInteger v = 0; v < 2; v++) {
                    [self checkAffectedCell2:cell cornerH:h andV:v];
                }
            }
            break;
            
        case 3:
            for (NSInteger h = 0; h < 2; h++) {
                for (NSInteger v = 0; v < 2; v++) {
                    [self checkAffectedCell3:cell cornerH:h andV:v];
                }
            }
            break;
    }
}

/**
 * 与えられた1のCellの与えられたコーナーの斜めに接するCellとの関係のチェックを行う.
 * @param cell 対象のCell
 * @param h 水平方向の位置（0:左側、1:右側)
 * @param v 鉛直方向の位置（0:上側、1:下側）
 */
- (void)checkAffectedCell1:(KSLCell *)cell cornerH:(NSInteger)h andV:(NSInteger)v
{
    KSLEdge *viEdge = h ? cell.rightEdge : cell.leftEdge;
    KSLEdge *hiEdge = v ? cell.bottomEdge : cell.topEdge;
    KSLEdge *voEdge = [viEdge straightEdgeOfLH:v];
    KSLEdge *hoEdge = [hiEdge straightEdgeOfLH:h];
    KSLNode *node = [hiEdge nodeOfLH:h];
    KSLGateDir dir = h == v ? KSLGateDirLU : KSLGateDirRU;
    KSLGateStatus gateStatus = [node gateStatusOfDir:dir];
    
    if (gateStatus == KSLGateStatusUnset) {
        gateStatus = [self gateStatus1WithHiEdge:hiEdge viEdge:viEdge hoEdge:hoEdge voEdge:voEdge];
        if (gateStatus != KSLGateStatusUnset) {
            if ([self setGateStatusOfNode:node andDir:dir toStatus:gateStatus]) {
                [affectedCells addObject:[hoEdge cellOfDir:v]];
            }
        } else {
            return;
        }
    }
    
    KSLEdge *oviEdge = h ? cell.leftEdge : cell.rightEdge;
    KSLEdge *ohiEdge = v ? cell.topEdge : cell.bottomEdge;
    KSLEdge *ovoEdge = [oviEdge straightEdgeOfLH:1-v];
    KSLEdge *ohoEdge = [ohiEdge straightEdgeOfLH:1-h];
    KSLNode *onode = [ohiEdge nodeOfLH:1-h];
    
    if (gateStatus == KSLGateStatusOpen) {
        // Openなら、対象コーナーの内側外側とも1本はOn、1本はOff
        [self fillOpenGateEdgesWithHiEdge:hiEdge viEdge:viEdge hoEdge:hoEdge voEdge:voEdge];
        
        if ([onode gateStatusOfDir:dir] == KSLGateStatusUnset) {
            // 逆側のコーナーはClose
            if ([self setGateStatusOfNode:onode andDir:dir toStatus:KSLGateStatusClose]) {
                [affectedCells addObject:[ohoEdge cellOfDir:1-v]];
            }
        }
        // 逆側のコーナーの内側はOff
        [self setCloseGateEdgesWithHEdge:ohiEdge vEdge:oviEdge toStatus:KSLEdgeStatusOff];
        // 外側は2本が同じ状態
        [self fillCloseGateEdgesWithHEdge:ohoEdge vEdge:ovoEdge];
    } else {
        [self setCloseGateEdgesWithHEdge:hiEdge vEdge:viEdge toStatus:KSLEdgeStatusOff];
        [self fillCloseGateEdgesWithHEdge:hoEdge vEdge:voEdge];
        
        if ([onode gateStatusOfDir:dir] == KSLGateStatusUnset) {
            if ([self setGateStatusOfNode:onode andDir:dir toStatus:KSLGateStatusOpen]) {
                [affectedCells addObject:[ohoEdge cellOfDir:1-v]];
            }
        }
        [self fillOpenGateEdgesWithHiEdge:ohiEdge viEdge:oviEdge hoEdge:ohoEdge voEdge:ovoEdge];
    }
}

/**
 * 与えられた2のCellの与えられたコーナーの斜めに接するCellとの関係のチェックを行う.
 * @param cell 対象のCell
 * @param h 水平方向の位置（0:左側、1:右側)
 * @param v 鉛直方向の位置（0:上側、1:下側）
 */
- (void)checkAffectedCell2:(KSLCell *)cell cornerH:(NSInteger)h andV:(NSInteger)v
{
    KSLEdge *viEdge = h ? cell.rightEdge : cell.leftEdge;
    KSLEdge *hiEdge = v ? cell.bottomEdge : cell.topEdge;
    KSLEdge *voEdge = [viEdge straightEdgeOfLH:v];
    KSLEdge *hoEdge = [hiEdge straightEdgeOfLH:h];
    KSLNode *node = [hiEdge nodeOfLH:h];
    KSLGateDir dir = h == v ? KSLGateDirLU : KSLGateDirRU;
    KSLGateStatus gateStatus = [node gateStatusOfDir:dir];
    KSLEdge *oviEdge = h ? cell.leftEdge : cell.rightEdge;
    KSLEdge *ohiEdge = v ? cell.topEdge : cell.bottomEdge;
    KSLEdge *ovoEdge = [oviEdge straightEdgeOfLH:1-v];
    KSLEdge *ohoEdge = [ohiEdge straightEdgeOfLH:1-h];
    
    if (gateStatus == KSLGateStatusUnset) {
        gateStatus = [self gateStatus2WithHiEdge:hiEdge viEdge:viEdge hoEdge:hoEdge voEdge:voEdge];
        if (gateStatus == KSLGateStatusUnset) {
            if (oviEdge.status == KSLEdgeStatusOff || ohiEdge.status == KSLEdgeStatusOff ||
                    ovoEdge.status == KSLEdgeStatusOn || ohoEdge.status == KSLEdgeStatusOn) {
                // 逆側のコーナーの内側のいずれかの辺ががOffまたは外側のいずれかの辺がOnなら
                if (voEdge.status == KSLEdgeStatusOn || hoEdge.status == KSLEdgeStatusOn) {
                    // 対象のコーナーの外側のいずれかの辺がOnならOpen
                    gateStatus = KSLGateStatusOpen;
                } else {
                    NSInteger dx = h ? 1 : -1;
                    NSInteger dy = v ? 1 : -1;
                    if ([_board get3Across2FromCell:cell withDx:dx dy:dy]) {
                        // 対象コーナーの斜め延長上に(間に2を挟んで)3があればOpen
                        gateStatus = KSLGateStatusOpen;
                    }
                }
            }
        }
        if (gateStatus != KSLGateStatusUnset) {
            if ([self setGateStatusOfNode:node andDir:dir toStatus:gateStatus]) {
                [affectedCells addObject:[hoEdge cellOfDir:v]];
            }
        } else {
            return;
        }
    }
    
    KSLNode *onode = [ohiEdge nodeOfLH:1-h];
    
    if (gateStatus == KSLGateStatusOpen) {
        // Openなら、対象コーナーの内側外側とも1本はOn、1本はOff
        [self fillOpenGateEdgesWithHiEdge:hiEdge viEdge:viEdge hoEdge:hoEdge voEdge:voEdge];
        
        if ([onode gateStatusOfDir:dir] == KSLGateStatusUnset) {
            if ([self setGateStatusOfNode:onode andDir:dir toStatus:KSLGateStatusOpen]) {
                [affectedCells addObject:[ohoEdge cellOfDir:1-v]];
            }
        }
        // 逆側のコーナーも内側外側とも1本はOn、1本はOff
        [self fillOpenGateEdgesWithHiEdge:ohiEdge viEdge:oviEdge hoEdge:ohoEdge voEdge:ovoEdge];
    } else {
        // Closeなら隣の2つのコーナーがOpen、対角のコーナーはClose
        KSLNode *dnode = [hiEdge nodeOfLH:1-h];
        KSLGateDir ddir = dir == KSLGateDirLU ? KSLGateDirRU : KSLGateDirLU;
        KSLEdge *dhoEdge = [hiEdge straightEdgeOfLH:1-h];
        KSLEdge *dvoEdge = [oviEdge straightEdgeOfLH:v];
        if ([dnode gateStatusOfDir:dir] == KSLGateStatusUnset) {
            if ([self setGateStatusOfNode:dnode andDir:ddir toStatus:KSLGateStatusOpen]) {
                [affectedCells addObject:[dhoEdge cellOfDir:v]];
            }
        }
        [self fillOpenGateEdgesWithHiEdge:hiEdge viEdge:oviEdge hoEdge:dhoEdge voEdge:dvoEdge];
        
        dnode = [viEdge nodeOfLH:1-v];
        dhoEdge = [ohiEdge straightEdgeOfLH:h];
        dvoEdge = [viEdge straightEdgeOfLH:1-v];
        if ([dnode gateStatusOfDir:dir] == KSLGateStatusUnset) {
            if ([self setGateStatusOfNode:dnode andDir:ddir toStatus:KSLGateStatusOpen]) {
                [affectedCells addObject:[dhoEdge cellOfDir:1-v]];
            }
        }
        [self fillOpenGateEdgesWithHiEdge:ohiEdge viEdge:viEdge hoEdge:dhoEdge voEdge:dvoEdge];
        
        [self fillCloseGateEdgesWithHEdge:hiEdge vEdge:viEdge];
        [self fillCloseGateEdgesWithHEdge:hoEdge vEdge:voEdge];
        
        if ([onode gateStatusOfDir:dir] == KSLGateStatusUnset) {
            if ([self setGateStatusOfNode:onode andDir:dir toStatus:KSLGateStatusClose]) {
                [affectedCells addObject:[ohoEdge cellOfDir:1-v]];
            }
        }
        [self fillCloseGateEdgesWithHEdge:ohiEdge vEdge:oviEdge];
        [self fillCloseGateEdgesWithHEdge:ohoEdge vEdge:ovoEdge];
        
        if (hoEdge.status == KSLEdgeStatusOff) {
            // Closeなコーナーの逆側のCellが3ならそのCellの軸対象のコーナーの内側の2辺がOn
            KSLCell *aCell = [oviEdge cellOfDir:1-h];
            if (aCell.number == 3) {
                KSLEdge *aEdge = h ? aCell.leftEdge : aCell.rightEdge;
                [self changeEdge:aEdge status:KSLEdgeStatusOn];
                [self changeEdge:[hiEdge straightEdgeOfLH:1-h] status:KSLEdgeStatusOn];
            }
            aCell = [ohiEdge cellOfDir:1-v];
            if (aCell.number == 3) {
                KSLEdge *aEdge = v ? aCell.topEdge : aCell.bottomEdge;
                [self changeEdge:aEdge status:KSLEdgeStatusOn];
                [self changeEdge:[viEdge straightEdgeOfLH:1-v] status:KSLEdgeStatusOn];
            }
        }
    }
}

/**
 * 与えられた3のCellの与えられたコーナーの斜めに接するCellとの関係のチェックを行う.
 * @param cell 対象のCell
 * @param h 水平方向の位置（0:左側、1:右側)
 * @param v 鉛直方向の位置（0:上側、1:下側）
 */
- (void)checkAffectedCell3:(KSLCell *)cell cornerH:(NSInteger)h andV:(NSInteger)v
{
    KSLEdge *viEdge = h ? cell.rightEdge : cell.leftEdge;
    KSLEdge *hiEdge = v ? cell.bottomEdge : cell.topEdge;
    KSLEdge *voEdge = [viEdge straightEdgeOfLH:v];
    KSLEdge *hoEdge = [hiEdge straightEdgeOfLH:h];
    KSLNode *node = [hiEdge nodeOfLH:h];
    KSLGateDir dir = h == v ? KSLGateDirLU : KSLGateDirRU;
    KSLGateStatus gateStatus = [node gateStatusOfDir:dir];
    
    if (gateStatus == KSLGateStatusUnset) {
        gateStatus = [self gateStatus3WithHiEdge:hiEdge viEdge:viEdge hoEdge:hoEdge voEdge:voEdge];
        if (gateStatus != KSLGateStatusUnset) {
            if ([self setGateStatusOfNode:node andDir:dir toStatus:gateStatus]) {
                [affectedCells addObject:[hoEdge cellOfDir:v]];
            }
        } else {
            return;
        }
    }
    
    KSLEdge *oviEdge = h ? cell.leftEdge : cell.rightEdge;
    KSLEdge *ohiEdge = v ? cell.topEdge : cell.bottomEdge;
    KSLEdge *ovoEdge = [oviEdge straightEdgeOfLH:1-v];
    KSLEdge *ohoEdge = [ohiEdge straightEdgeOfLH:1-h];
    KSLNode *onode = [ohiEdge nodeOfLH:1-h];
    
    if (gateStatus == KSLGateStatusOpen) {
        // Openなら、対象コーナーの内側外側とも1本はOn、1本はOff
        [self fillOpenGateEdgesWithHiEdge:hiEdge viEdge:viEdge hoEdge:hoEdge voEdge:voEdge];
        
        if ([onode gateStatusOfDir:dir] == KSLGateStatusUnset) {
            if ([self setGateStatusOfNode:onode andDir:dir toStatus:KSLGateStatusClose]) {
                [affectedCells addObject:[ohoEdge cellOfDir:1-v]];
            }
        }
        // 逆側コーナーの内側2辺はOn
        [self setCloseGateEdgesWithHEdge:ohiEdge vEdge:oviEdge toStatus:KSLEdgeStatusOn];
        // 外側2辺はOff
        [self setCloseGateEdgesWithHEdge:ohoEdge vEdge:ovoEdge toStatus:KSLEdgeStatusOff];
    } else {
        [self setCloseGateEdgesWithHEdge:hiEdge vEdge:viEdge toStatus:KSLEdgeStatusOn];
        [self setCloseGateEdgesWithHEdge:hoEdge vEdge:voEdge toStatus:KSLEdgeStatusOff];
        
        if ([onode gateStatusOfDir:dir] == KSLGateStatusUnset) {
            if ([self setGateStatusOfNode:onode andDir:dir toStatus:KSLGateStatusOpen]) {
                [affectedCells addObject:[ohoEdge cellOfDir:1-v]];
            }
        }
        [self fillOpenGateEdgesWithHiEdge:ohiEdge viEdge:oviEdge hoEdge:ohoEdge voEdge:ovoEdge];
    }
}

/**
 * 与えられたNodeの与えられた方向のGateの状態を、与えられた状態に変更する.
 * @param node 対象のNode
 * @param dir 方向
 * @param status 状態
 * @return 実際に変更されたか（既に変更されていた場合はNO）
 */
- (BOOL)setGateStatusOfNode:(KSLNode *)node andDir:(KSLGateDir)dir toStatus:(KSLGateStatus)status
{
    KSLGateStatus oldStatus = [node gateStatusOfDir:dir];
    if (oldStatus == KSLGateStatusUnset) {
        [node setGateStatusOfDir:dir toStatus:status];
        if (_currentStep) {
            [_currentStep addObject:[[KSLAction alloc]
                            initWithType:(dir ? KSLActionTypeRUGateStatus : KSLActionTypeLUGateStatus)
                            target:node fromValue:oldStatus toValue:status]];
        }
        return YES;
    }
    return NO;
}

/**
 * 1のセルの1つのコーナーのGateの状態を得る
 * @param hiEdge 水平方向の内側のEdge
 * @param viEdge 鉛直方向の内側のEdge
 * @param hoEdge 水平方向の外側のEdge
 * @param voEdge 鉛直方向の外側のEdge
 * @return Gateの状態
 */
- (KSLGateStatus)gateStatus1WithHiEdge:(KSLEdge *)hiEdge viEdge:(KSLEdge *)viEdge
                                   hoEdge:(KSLEdge *)hoEdge voEdge:(KSLEdge *)voEdge
{
    if (hiEdge.status == KSLEdgeStatusOn || viEdge.status == KSLEdgeStatusOn) {
        return KSLGateStatusOpen;
    } else if (hiEdge.status == KSLEdgeStatusOff && viEdge.status == KSLEdgeStatusOff) {
        return KSLGateStatusClose;
    }
    if (hoEdge.status == KSLEdgeStatusOn) {
        if (voEdge.status == KSLEdgeStatusOn) {
            return KSLGateStatusClose;
        } else if (voEdge.status == KSLEdgeStatusOff) {
            return KSLGateStatusOpen;
        }
    } else if (hoEdge.status == KSLEdgeStatusOff) {
        if (voEdge.status == KSLEdgeStatusOn) {
            return KSLGateStatusOpen;
        } else if (voEdge.status == KSLEdgeStatusOff) {
            return KSLGateStatusClose;
        }
    }
    
    return KSLGateStatusUnset;
}

/**
 * 2のセルの1つのコーナーのGateの状態を得る
 * @param hiEdge 水平方向の内側のEdge
 * @param viEdge 鉛直方向の内側のEdge
 * @param hoEdge 水平方向の外側のEdge
 * @param voEdge 鉛直方向の外側のEdge
 * @return Gateの状態
 */
- (KSLGateStatus)gateStatus2WithHiEdge:(KSLEdge *)hiEdge viEdge:(KSLEdge *)viEdge
                                   hoEdge:(KSLEdge *)hoEdge voEdge:(KSLEdge *)voEdge
{
    if (hiEdge.status == KSLEdgeStatusOn) {
        if (viEdge.status == KSLEdgeStatusOn) {
            return KSLGateStatusClose;
        } else if (viEdge.status == KSLEdgeStatusOff) {
            return KSLGateStatusOpen;
        }
    } else if (hiEdge.status == KSLEdgeStatusOff) {
        if (viEdge.status == KSLEdgeStatusOn) {
            return KSLGateStatusOpen;
        } else if (viEdge.status == KSLEdgeStatusOff) {
            return KSLGateStatusClose;
        }
    }
    if (hoEdge.status == KSLEdgeStatusOn) {
        if (voEdge.status == KSLEdgeStatusOn) {
            return KSLGateStatusClose;
        } else if (voEdge.status == KSLEdgeStatusOff) {
            return KSLGateStatusOpen;
        }
    } else if (hoEdge.status == KSLEdgeStatusOff) {
        if (voEdge.status == KSLEdgeStatusOn) {
            return KSLGateStatusOpen;
        } else if (voEdge.status == KSLEdgeStatusOff) {
            return KSLGateStatusClose;
        }
    }
    return KSLGateStatusUnset;
}

/**
 * 3のセルの1つのコーナーのGateの状態を得る
 * @param hiEdge 水平方向の内側のEdge
 * @param viEdge 鉛直方向の内側のEdge
 * @param hoEdge 水平方向の外側のEdge
 * @param voEdge 鉛直方向の外側のEdge
 * @return Gateの状態
 */
- (KSLGateStatus)gateStatus3WithHiEdge:(KSLEdge *)hiEdge viEdge:(KSLEdge *)viEdge
                                   hoEdge:(KSLEdge *)hoEdge voEdge:(KSLEdge *)voEdge
{
    if (hiEdge.status == KSLEdgeStatusOff || viEdge.status == KSLEdgeStatusOff) {
        return KSLGateStatusOpen;
    } else if (hiEdge.status == KSLEdgeStatusOn && viEdge.status == KSLEdgeStatusOn) {
        return KSLGateStatusClose;
    }
    
    if (hoEdge.status == KSLEdgeStatusOn || voEdge.status == KSLEdgeStatusOn) {
        return KSLGateStatusOpen;
    } else if (hoEdge.status == KSLEdgeStatusOff && voEdge.status == KSLEdgeStatusOff) {
        return KSLGateStatusClose;
    }
    return KSLGateStatusUnset;
}

/**
 * 開いたGateの内外の2組のEdgeの状態を（可能であれば）設定する
 * @param hiEdge 水平方向の内側のEdge
 * @param viEdge 鉛直方向の内側のEdge
 * @param hoEdge 水平方向の外側のEdge
 * @param voEdge 鉛直方向の外側のEdge
 */
- (void)fillOpenGateEdgesWithHiEdge:(KSLEdge *)hiEdge viEdge:(KSLEdge *)viEdge
                             hoEdge:(KSLEdge *)hoEdge voEdge:(KSLEdge *)voEdge
{
    if (hiEdge.status == KSLEdgeStatusOn) {
        [self changeEdge:viEdge status:KSLEdgeStatusOff];
    } else if (hiEdge.status == KSLEdgeStatusOff) {
        [self changeEdge:viEdge status:KSLEdgeStatusOn];
    } else if (viEdge.status == KSLEdgeStatusOn) {
        [self changeEdge:hiEdge status:KSLEdgeStatusOff];
    } else if (viEdge.status == KSLEdgeStatusOff) {
        [self changeEdge:hiEdge status:KSLEdgeStatusOn];
    }
    
    if (hoEdge.status == KSLEdgeStatusOn) {
        [self changeEdge:voEdge status:KSLEdgeStatusOff];
    } else if (hoEdge.status == KSLEdgeStatusOff) {
        [self changeEdge:voEdge status:KSLEdgeStatusOn];
    } else if (voEdge.status == KSLEdgeStatusOn) {
        [self changeEdge:hoEdge status:KSLEdgeStatusOff];
    } else if (voEdge.status == KSLEdgeStatusOff) {
        [self changeEdge:hoEdge status:KSLEdgeStatusOn];
    }
}

/**
 * 閉じたGateの内部あるいは外部の1組のEdgeの状態を（可能であれば）設定する
 * @param hEdge 水平方向のEdge
 * @param vEdge 鉛直方向のEdge
 */
- (void)fillCloseGateEdgesWithHEdge:(KSLEdge *)hEdge vEdge:(KSLEdge *)vEdge
{
    if (hEdge.status == KSLEdgeStatusOn) {
        [self changeEdge:vEdge status:KSLEdgeStatusOn];
    } else if (hEdge.status == KSLEdgeStatusOff) {
        [self changeEdge:vEdge status:KSLEdgeStatusOff];
    } else if (vEdge.status == KSLEdgeStatusOn) {
        [self changeEdge:hEdge status:KSLEdgeStatusOn];
    } else if (vEdge.status == KSLEdgeStatusOff) {
        [self changeEdge:hEdge status:KSLEdgeStatusOff];
    }
}

/**
 * 閉じたGateの内部あるいは外部の1組のEdgeの状態を強制的に所定の状態に設定する
 * @param hEdge 水平方向のEdge
 * @param vEdge 鉛直方向のEdge
 * @param status 設定する状態
 */
- (void)setCloseGateEdgesWithHEdge:(KSLEdge *)hEdge vEdge:(KSLEdge *)vEdge
                          toStatus:(KSLEdgeStatus)status
{
    [self changeEdge:hEdge status:status];
    [self changeEdge:vEdge status:status];
}

/**
 * 指定のインデックス以降のステップのEdgeの状態を変更した処理のリストを出力する.
 * @param index ステップのインデックス
 */
- (void)dumpStepsFromIndex:(NSInteger)index
{
    NSInteger i = 0;
    for (NSArray *step in _steps) {
        if (i >= index) {
            printf("STEP%02ld:", (long)i);
            NSInteger m = 0;
            for (KSLAction *action in step) {
                if (action.type == KSLActionTypeEdgeStatus) {
                    m++;
                    if (m > 10) {
                        printf("\n       ");
                        m = 0;
                    }
                    printf("%s-%ld,", ((KSLEdge *)(action.target)).description.UTF8String,
                           (long)action.newValue);
                }
            }
            printf("\n");
        }
        i++;
    }
}

@end

