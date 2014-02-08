//
//  KSLProblem.m
//  SLPlayer
//
//  Created by KO on 13/11/02.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import "KSLProblem.h"

#pragma mark - KSLAction

@implementation KSLAction

- (id)initWithType:(KSLActionType)aType target:(id)aTarget
         fromValue:(int)aOldValue toValue:(int)aNewValue
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
    return [NSString stringWithFormat:@"%d:%@:%d:%d", _type, _target, _oldValue, _newValue];
}

@end


#pragma mark - KSLProblem

@implementation KSLProblem
{
    // セルの数値の配列
    NSMutableArray *_data;
}

#pragma mark - 初期化

- (id)initWithWidth:(NSInteger)width andHeight:(NSInteger)height data:(NSInteger *)data
{
    self = [super init];
    if (self) {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        _uid = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
        self.title = @"未定";
        self.status = KSLProblemStatusNotStarted;
        self.difficulty = -1;
        self.evaluation = -1;
        CFRelease(uuid);
        _width = width;
        _height = height;
        NSInteger count = width * height;
        _data = [NSMutableArray arrayWithCapacity:count];
        for (int i = 0; i < count; i++) {
            _data[i] = @(data[i]);
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
        _path = path;
        self.title = json[@"title"];
        self.status = [json[@"status"] integerValue];
        self.difficulty = [json[@"difficulty"] integerValue];
        self.evaluation = [json[@"evaluation"] integerValue];
        _width = [json[@"width"] integerValue];
        _height = [json[@"height"] integerValue];
        _data = json[@"data"];
        self.elapsedSeconds = json[@"elapsedSeconds"];
    }
    return self;
}

- (id)initWithProblem:(KSLProblem *)original
{
    self = [super init];
    if (self) {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        _uid = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
        _path = original.path;
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

- (void)saveToFile:(NSString *)directory
{
    NSString *fileName = [_uid stringByAppendingPathExtension:@"problem"];
    _path = [directory stringByAppendingPathComponent:fileName];
    [self save];
}


- (void)save
{
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"title"] = _title;
    json[@"status"] = @(_status);
    json[@"difficulty"] = @(_difficulty);
    json[@"evaluation"] = @(_evaluation);    json[@"width"] = @(_width);
    json[@"height"] = @(_height);
    
    json[@"data"] = _data;
    json[@"elapsedSeconds"] = _elapsedSeconds;
    
    NSError *error = nil;
    [[NSJSONSerialization dataWithJSONObject:json options:0 error:&error]
     writeToFile:_path atomically:YES];
    if (error) {
        [[NSException exceptionWithName:error.description reason:_path userInfo:nil] raise];
    }
}

- (NSInteger)valueOfX:(NSInteger)x andY:(NSInteger)y
{
    return [((NSNumber *)_data[y * _width + x]) integerValue];
}

- (void)dump
{
    for (int y = 0; y < _height; y++) {
        for (int x = 0; x < _width; x++) {
            int val = [self valueOfX:x andY:y];
            if (val >= 0) {
                printf("%d", val);
            } else {
                printf("-");
            }
        }
        printf("\n");
    }
}

@end
