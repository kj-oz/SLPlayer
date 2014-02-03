//
//  KSLProblemDelegate.h
//  SLPlayer
//
//  Created by KO on 2014/01/19.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

#define KSLPROBLEM_MARGIN           1.0
#define KSLPROBLEM_BORDER_WIDTH     0.2
#define KSLPROBLEM_MINIMUM_PITCH    44
#define KSLPROBLEM_MAXIMUM_PITCH    88

@class KSLBoard;

@protocol KSLProblemViewDelegate <NSObject>

@property (nonatomic, readonly) KSLBoard *board;

// 拡大画面で表示中の領域（原点が左上のNode、単位長さが１つのCellの幅の座標系での表現）
@property (nonatomic, assign) CGRect zoomedArea;

@property (nonatomic, readonly) CGRect problemArea;


@end
