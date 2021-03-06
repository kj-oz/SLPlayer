//
//  KSLPlayer.m
//  SLPlayer
//
//  Created by KO on 2014/01/18.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import "KSLPlayer.h"
#import "KSLBoard.h"
#import "KSLProblem.h"
#import "KSLProblemManager.h"

@implementation KSLPlayer
{
    // 盤面
    KSLBoard *_board;
    
    // パス
    NSString *_path;
    
    // ステップを保持する配列（Mutableとするための再宣言
    NSMutableArray *_steps;
}

#pragma mark - 初期化

- (id)initWithProblem:(KSLProblem *)problem
{
    self = [super init];
    if (self) {
        _problem = problem;
        _board = [[KSLBoard alloc] initWithProblem:_problem];
        
        NSString *fileName = [problem.uid stringByAppendingPathExtension:@"play"];
        KSLProblemManager *pm = [KSLProblemManager sharedManager];
        _path = [pm.currentWorkbookDir stringByAppendingPathComponent:fileName];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:_path]) {
            NSError *error = nil;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:
                                  [NSData dataWithContentsOfFile:_path] options:0 error:&error];
            if (error) {
                [[NSException exceptionWithName:error.description reason:_path userInfo:nil] raise];
            }
            self.currentIndex = [json[@"currentIndex"] integerValue];
            self.fixedIndex = [json[@"fixedIndex"] integerValue];
            self.zoomedArea = CGRectFromString(json[@"zoomedArea"]);
            [self loadStepsFromJson:json[@"steps"]];
        } else {
            _currentIndex = -1;
            _fixedIndex = -1;
            _steps = [NSMutableArray array];
            _zoomedArea = CGRectZero;
        }
        
    }
    return self;
}

#pragma mark - 保存

- (void)save
{
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"currentIndex"] = @(_currentIndex);
    json[@"fixedIndex"] = @(_fixedIndex);
    json[@"steps"] = [self stringArrayFromSteps];
    json[@"zoomedArea"] = NSStringFromCGRect(_zoomedArea);
    
    NSError *error = nil;
    [[NSJSONSerialization dataWithJSONObject:json options:0 error:&error]
                                                    writeToFile:_path atomically:YES];
    if (error) {
        [[NSException exceptionWithName:error.description reason:_path userInfo:nil] raise];
    }
}

#pragma mark - 盤面の操作

- (void)addStep:(NSArray *)step
{
    while (_currentIndex < _steps.count - 1) {
        [_steps removeLastObject];
    }
    [_steps addObject:[step copy]];
    _currentIndex++;
}

- (void)clear
{
    _currentIndex = -1;
    _fixedIndex = -1;
    [_steps removeAllObjects];
    [_board clear];
}

- (void)erase
{
    _currentIndex = _fixedIndex;
    while (_currentIndex < _steps.count - 1) {
        [_steps removeLastObject];
    }
    [_board erase];
}

- (void)fix
{
    _fixedIndex = _currentIndex;
    [_board fixStatus];
}

- (void)changeAction:(NSInteger)newValue
{
    NSArray *step = [_steps objectAtIndex:_currentIndex];
    KSLAction *action = [step lastObject];
    [action changeNewValueTo:newValue];
}

- (void)undo
{
    if (_currentIndex > _fixedIndex) {
        NSArray *step = [_steps lastObject];
        for (KSLAction *action in step.reverseObjectEnumerator) {
            [self undoAction:action];
        }
        _currentIndex--;
    }
}

#pragma mark - 盤面のチェック

- (KSLLoopStatus)isLoopFinished
{
    KSLAction *action = [[_steps lastObject] lastObject];
    KSLEdge *edge = action.target;
    return [_board loopStatusOfEdge:edge];
}

#pragma mark - プライベートメッソド（初期化)

/**
 * 与えられたJSONをパースした配列を元に、stepsを復元する.
 * @param jsonArray JSONをパースした配列
 */
- (void)loadStepsFromJson:(NSArray *)jsonArray
{
    _steps = [NSMutableArray arrayWithCapacity:[jsonArray count]];
    NSInteger index = 0;
    for (NSArray *actions in jsonArray) {
        NSMutableArray *step = [NSMutableArray arrayWithCapacity:[actions count]];
        for (NSString *actionString in actions) {
            KSLAction *action = [self parseActionFromString:actionString];
            [step addObject:action];
            if (index <= _currentIndex) {
                [self doAction:action];
            }
        }
        [_steps addObject:step];
        if (index == _fixedIndex) {
            [_board fixStatus];
        }
        index++;
    }
}

/**
 * 操作をに対するjson文字列を得る.
 * @return 操作をに対するjson文字列
 */
- (NSArray *)stringArrayFromSteps
{
    NSMutableArray *jsonArray = [NSMutableArray arrayWithCapacity:[_steps count]];
    for (NSArray *actions in _steps) {
        NSMutableArray *step = [NSMutableArray arrayWithCapacity:[actions count]];
        for (KSLAction *action in actions) {
            [step addObject:action.description];
        }
        [jsonArray addObject:step];
    }
    return jsonArray;
}

/**
 * 与えられた文字列からActionを復元する.
 * @param string 文字列
 * @return 復元したAction
 */
- (KSLAction *)parseActionFromString:(NSString *)string
{
    NSArray *parts = [string componentsSeparatedByString:@":"];
    KSLActionType type = [((NSString *)parts[0]) intValue];
    if (type != KSLActionTypeEdgeStatus) {
        return nil;
    }
    KSLEdge *edge = [_board findEdgeWithId:parts[1]];
    KSLEdgeStatus oldStatus = [((NSString *)parts[2]) intValue];
    KSLEdgeStatus newStatus = [((NSString *)parts[3]) intValue];
    return [[KSLAction alloc] initWithType:type target:edge fromValue:oldStatus toValue:newStatus];
}

/**
 * アクションを実行する.
 * @param action アクション
 */
- (void)doAction:(KSLAction *)action
{
    KSLEdge *edge = nil;
    switch (action.type) {
        case KSLActionTypeEdgeStatus:
            edge = action.target;
            edge.status = action.newValue;
            break;
            
        default:
            break;
    }
}

/**
 * アクションを取り消す.
 * @param action アクション
 */
- (void)undoAction:(KSLAction *)action
{
    KSLEdge *edge = nil;
    switch (action.type) {
        case KSLActionTypeEdgeStatus:
            edge = action.target;
            edge.status = action.oldValue;
            break;
            
        default:
            break;
    }
}

@end
