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
    // 問題
    __weak KSLProblem *_problem;
    
    // 盤面
    KSLBoard *_board;
    
    // パス
    NSString *_path;
    
    // ステップを保持する配列（Mutableとするための再宣言
    NSMutableArray *_steps;
}

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
            [self loadStepsFromJson:json[@"steps"]];
        } else {
            _currentIndex = -1;
            _fixedIndex = -1;
            _steps = [NSMutableArray array];
        }
    }
    return self;
}

- (void)save
{
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"currentIndex"] = @(_currentIndex);
    json[@"fixedIndex"] = @(_fixedIndex);
    
    NSError *error = nil;
    [[NSJSONSerialization dataWithJSONObject:json options:0 error:&error]
                                                    writeToFile:_path atomically:YES];
    if (error) {
        [[NSException exceptionWithName:error.description reason:_path userInfo:nil] raise];
    }
}


#pragma mark - プライベートメッソド（初期化)

/**
 * 与えられたJSONをパースした配列を元に、stepsを復元する.
 * @param jsonArray JSONをパースした配列
 */
- (void)loadStepsFromJson:(NSArray *)jsonArray
{
    _steps = [NSMutableArray arrayWithCapacity:[jsonArray count]];
    int index = 0;
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
 * 与えられた文字列からActionを復元する.
 * @param string 文字列
 * @return 復元したAction
 */
- (KSLAction *)parseActionFromString:(NSString *)string
{
    NSArray *parts = [string componentsSeparatedByString:@":"];
    KSLActionType type = [((NSString *)parts[0]) intValue];
    if (type != KSLActiomTypeEdgeStatus) {
        return nil;
    }
    KSLEdge *edge = [_board findEdgeWithId:parts[1]];
    KSLEdgeStatus oldStatus = [((NSString *)parts[2]) intValue];
    KSLEdgeStatus newStatus = [((NSString *)parts[3]) intValue];
    return [[KSLAction alloc] initWithType:type target:edge fromValue:oldStatus toValue:newStatus];
}

/**
 * 
 * @param action アクションを実行する
 */
- (void)doAction:(KSLAction *)action
{
    KSLEdge *edge = nil;
    switch (action.type) {
        case KSLActiomTypeEdgeStatus:
            edge = action.target;
            edge.status = action.newValue;
            break;
            
        default:
            break;
    }
}

@end
