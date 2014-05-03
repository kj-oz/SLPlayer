//
//  KSLProblemListCell.h
//  SLPlayer
//
//  Created by KO on 2014/05/03.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KSLProblemListCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (nonatomic) IBOutlet UILabel *sizeLabel;

@property (nonatomic) IBOutlet UILabel *difficultyLabel;

@property (nonatomic) IBOutlet UILabel *statusLabel;

@end
