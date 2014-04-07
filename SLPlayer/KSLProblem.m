//
//  KSLProblem.m
//  SLPlayer
//
//  Created by KO on 13/11/02.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import "KSLProblem.h"
#import "KSLProblemManager.h"

#pragma mark - KSLAction

@implementation KSLAction

- (id)initWithType:(KSLActionType)aType target:(id)aTarget
         fromValue:(NSInteger)aOldValue toValue:(NSInteger)aNewValue
{
    self = [super init];
    if (self) {
        _type = aType;
        _target = aTarget;
        _oldValue = aOldValue;
        _newValue = aNewValue;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%ld:%@:%ld:%ld", (long)_type, _target, (long)_oldValue, (long)_newValue];
}

- (void)changeNewValueTo:(NSInteger)aNewValue
{
    _newValue = aNewValue;
}

@end


#pragma mark - KSLProblem

@implementation KSLProblem
{
    // セルの数値の配列
    NSMutableArray *_data;
    
    //
    NSMutableArray *_elapsedSeconds;
}

#pragma mark - 初期化

- (id)initWithWidth:(NSInteger)width andHeight:(NSInteger)height data:(int *)data
{
    self = [super init];
    if (self) {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        _uid = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
        CFRelease(uuid);
        self.title = @"未定";
        self.status = KSLProblemStatusNotStarted;
        self.difficulty = 0;
        self.evaluation = 0;
        _width = width;
        _height = height;
        NSInteger count = width * height;
        _data = [NSMutableArray arrayWithCapacity:count];
        for (NSInteger i = 0; i < count; i++) {
            _data[i] = data ? @(data[i]) : @(-1);
        }
        _elapsedSeconds = [NSMutableArray array];
    }
    return self;
}

- (id)initWithFile:(NSString *)path
{
    self = [super init];
    if (self) {
        NSError *error = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:
                            [NSData dataWithContentsOfFile:path] options:0 error:&error];
        if (error) {
            [[NSException exceptionWithName:error.description reason:path userInfo:nil] raise];
        }
        _uid = [[path lastPathComponent] stringByDeletingPathExtension];
        self.title = json[@"title"];
        self.status = [json[@"status"] integerValue];
        self.difficulty = [json[@"difficulty"] integerValue];
        self.evaluation = [json[@"evaluation"] integerValue];
        _width = [json[@"width"] integerValue];
        _height = [json[@"height"] integerValue];
        _data = [json[@"data"] mutableCopy];
        self.elapsedSeconds = [json[@"elapsedSeconds"] mutableCopy];
    }
    return self;
}

- (id)initWithProblem:(KSLProblem *)original
{
    self = [super init];
    if (self) {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        _uid = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
        CFRelease(uuid);
        self.title = original.title;
        self.status = original.status;
        self.difficulty = original.difficulty;
        self.evaluation = original.evaluation;
        _width = original.width;
        _height = original.height;
        _data = [original.data mutableCopy];
        self.elapsedSeconds = [original.elapsedSeconds mutableCopy];
    }
    return self;
}

- (void)updateWithProblem:(KSLProblem *)original
{
    self.title = original.title;
    self.difficulty = original.difficulty;
    self.evaluation = original.evaluation;
    _data = [original.data mutableCopy];
}

#pragma mark - 保存

- (void)saveToFile:(NSString *)directory
{
    NSString *fileName = [_uid stringByAppendingPathExtension:@"problem"];
    NSString *path = [directory stringByAppendingPathComponent:fileName];
    
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"title"] = _title;
    json[@"status"] = @(_status);
    json[@"difficulty"] = @(_difficulty);
    json[@"evaluation"] = @(_evaluation);
    json[@"width"] = @(_width);
    json[@"height"] = @(_height);
    json[@"data"] = _data;
    json[@"elapsedSeconds"] = _elapsedSeconds;
    
    NSError *error = nil;
    [[NSJSONSerialization dataWithJSONObject:json options:0 error:&error]
     writeToFile:path atomically:YES];
    if (error) {
        [[NSException exceptionWithName:error.description reason:path userInfo:nil] raise];
    }
}


- (void)save
{
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    [self saveToFile:pm.currentWorkbookDir];
}

- (NSInteger)valueOfX:(NSInteger)x andY:(NSInteger)y
{
    return [((NSNumber *)_data[y * _width + x]) integerValue];
}

#pragma mark - 出力

- (void)dump
{
    for (NSInteger y = 0; y < _height; y++) {
        for (NSInteger x = 0; x < _width; x++) {
            NSInteger val = [self valueOfX:x andY:y];
            if (val >= 0) {
                printf("%ld", (long)val);
            } else {
                printf("-");
            }
        }
        printf("\n");
    }
}

- (NSString *)statusString
{
    switch (_status) {
        case KSLProblemStatusEditing:
            return @"編集中";
        case KSLProblemStatusNotStarted:
            return @"未着手";
        case KSLProblemStatusSolving:
        {
            NSInteger sec = ((NSNumber *)[_elapsedSeconds lastObject]).intValue;
            return [NSString stringWithFormat:@"未了（%.1f分）", (sec / 60.0)];
        }
        case KSLProblemStatusSolved:
            return @"完了";
        default:
            return @"不明";
    }
}

- (NSString *)elapsedTimeString
{
    NSInteger finishedCount = _elapsedSeconds.count - (_status == KSLProblemStatusSolving ? 1 : 0);
    if (finishedCount) {
        NSMutableString *elapsed = [NSMutableString stringWithString:@"("];
        for (NSInteger i = 0; i < finishedCount; i++) {
            NSInteger minute = (NSInteger)(((NSNumber *)_elapsedSeconds[i]).intValue / 60.0 + 0.5);
            [elapsed appendFormat:@"%ld分,", (long)minute];
        }
        [elapsed replaceCharactersInRange:NSMakeRange(elapsed.length - 2, 1) withString:@")"];
        
        return elapsed;
    } else {
        return @"";
    }
}

- (NSString *)difficultyString
{
    return [NSString stringWithFormat:@"★%d", _difficulty];
}

- (NSString *)evaluationString
{
    return @[@"", @"駄作", @"平凡", @"秀作"][_evaluation];
}

- (void)updateElapsedSecond:(NSInteger)sec
{
    [_elapsedSeconds setObject:@(sec) atIndexedSubscript:_elapsedSeconds.count - 1];
}

- (void)addElapsedSecond:(NSInteger)sec
{
    [_elapsedSeconds addObject:@(sec)];
}


@end
