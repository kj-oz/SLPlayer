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
        _width = width;
        _height = height;
        NSInteger count = width * height;
        _data = [NSMutableArray arrayWithCapacity:count];
        for (NSInteger i = 0; i < count; i++) {
            _data[i] = data ? @(data[i]) : @(-1);
        }
        _elapsedSecond = 0;
        _resetCount = 0;
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
        _width = [json[@"width"] integerValue];
        _height = [json[@"height"] integerValue];
        _data = [json[@"data"] mutableCopy];
        self.elapsedSecond = [json[@"elapsedSecond"] integerValue];
        self.resetCount = [json[@"resetCount"] integerValue];
    }
    return self;
}

- (id)initWithJson:(NSDictionary *)json
{
    self = [super init];
    if (self) {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        _uid = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
        CFRelease(uuid);

        self.title = json[@"title"];
        self.status = [json[@"status"] integerValue];
        self.difficulty = [json[@"difficulty"] integerValue];
        _width = [json[@"width"] integerValue];
        _height = [json[@"height"] integerValue];
        _data = [json[@"data"] mutableCopy];
        self.elapsedSecond = [json[@"elapsedSecond"] integerValue];
        self.resetCount = [json[@"resetCount"] integerValue];
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
        _width = original.width;
        _height = original.height;
        _data = [original.data mutableCopy];
        self.elapsedSecond = original.elapsedSecond;
        self.resetCount = original.resetCount;
    }
    return self;
}

- (void)updateWithProblem:(KSLProblem *)original
{
    self.title = original.title;
    self.difficulty = original.difficulty;
    _data = [original.data mutableCopy];
}

- (void)rotate
{
    NSMutableArray *data = [_data mutableCopy];
    for (NSInteger i = 0, n = data.count; i < n; i++) {
        data[i] = @(-1);
    }
    for (NSInteger y = 0; y < _height; y++) {
        for (NSInteger x = 0; x < _width; x++) {
            NSInteger val = [self valueOfX:x andY:y];
            NSInteger i = (_width - 1 - x) * _height + y;
            data[i] = @(val);
        }
    }
    _data = data;
    
    NSInteger work = _width;
    _width = _height;
    _height = work;
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
    json[@"width"] = @(_width);
    json[@"height"] = @(_height);
    json[@"data"] = _data;
    json[@"elapsedSecond"] = @(_elapsedSecond);
    json[@"resetCount"] = @(_resetCount);
    
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
            return @"作成中";
        case KSLProblemStatusNotStarted:
            return @"未着手";
        case KSLProblemStatusSolving:
            return [self elapsedTimeString];
        case KSLProblemStatusSolved:
            return [NSString stringWithFormat:@"完了（%@）", [self elapsedTimeString]];
        default:
            return @"不明";
    }
}

- (NSString *)elapsedTimeString
{
    if (_elapsedSecond > 0) {
        NSString *sec = [NSString stringWithFormat:@"%ld:%02ld:%02ld",
                         (long)(_elapsedSecond / 3600), (long)(_elapsedSecond % 3600) / 60,
                         (long)(_elapsedSecond % 60)];
        if (_resetCount > 0) {
            return [NSString stringWithFormat:@"%@ リセット %ld 回", sec, (long)_resetCount];
        } else {
            return sec;
        }
    } else {
        return @"";
    }
}

- (NSString *)difficultyString
{
    return [NSString stringWithFormat:@"★%ld", (long)_difficulty];
}

@end
