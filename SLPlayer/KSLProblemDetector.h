//
//  KSLImageRecognizer.h
//  SLPlayer
//
//  Created by KO on 13/10/20.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSLProblem;

/**
 * 与えられた画像からスリザーリンクの問題を自動認識する機能を提供するクラス.
 */
@interface KSLProblemDetector : NSObject

/**
 * 与えられた画像から問題を自動認識する.
 * @param image 元画像
 * @return 認識できた問題、認識に失敗した場合nil
 */
- (KSLProblem *)detectProblemFromImage:(UIImage *)image;

@end
