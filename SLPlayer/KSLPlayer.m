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

@implementation KSLPlayer
{
    __weak KSLProblem *_problem;
    
    KSLBoard *_board;
    
    NSMutableArray *_steps;
}

- (id)initWithProblem:(KSLProblem *)problem
{
    self = [super init];
    if (self) {
        NSError *error = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:
                              [NSData dataWithContentsOfFile:self.path] options:0 error:&error];
        if (error) {
            [[NSException exceptionWithName:error.description reason:self.path userInfo:nil] raise];
        }
        
        _problem = problem;
        _board = [[KSLBoard alloc] initWithProblem:_problem];
        
        self.currentIndex = [json[@"currentIndex"] integerValue];
        self.fixedIndex = [json[@"fixedIndex"] integerValue];
        [self loadStepsFromJson:json[@"steps"]];
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
                                                    writeToFile:self.path atomically:YES];
    if (error) {
        [[NSException exceptionWithName:error.description reason:self.path userInfo:nil] raise];
    }
}

- (void)loadStepsFromJson:(NSArray *)jsonArray
{
    _steps = [NSMutableArray arrayWithCapacity:[jsonArray count]];
    int index = 0;
    for (NSArray *actions in jsonArray) {
        NSMutableArray *step = [NSMutableArray arrayWithCapacity:[actions count]];
        for (NSString *actionString in actions) {
            KSLAction *action = [self parseActionFromString:actionString];
            [step addObject:action];
            [self doAction:action];
        }
        [_steps addObject:step];
        if (index == _fixedIndex) {
            [_board fixStatus];
        }
        index++;
    }
}

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

- (NSString *)path
{
    return [_problem.path stringByReplacingOccurrencesOfString:@".problem" withString:@".play"];
}

@end
