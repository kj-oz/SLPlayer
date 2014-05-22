//
//  KSLProblemListCell.h
//  SLPlayer
//
//  Created by KO on 2014/05/03.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * 問題をテーブルビューに表示するためのセル
 */
@interface KSLProblemListCell : UITableViewCell

// 名称のラベル
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

// サイズのラベル
@property (nonatomic) IBOutlet UILabel *sizeLabel;

// 難易度のラベル
@property (nonatomic) IBOutlet UILabel *difficultyLabel;

// 状態のラベル
@property (nonatomic) IBOutlet UILabel *statusLabel;

@end
