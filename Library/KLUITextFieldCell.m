//
//  PRTextFieldCell.m
//  PDFReader
//
//  Created by KO on 12/01/16.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import "KLUITextFieldCell.h"

@implementation KLUITextFieldCell

#pragma mark - 初期化

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _textField = [[UITextField alloc] initWithFrame:CGRectZero];
        _textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [self.contentView addSubview:_textField];
    }
    return self;
}

#pragma mark - 描画処理

- (void)layoutSubviews {
    [super layoutSubviews];
    _textField.frame = CGRectInset(self.contentView.bounds, 10, 0);
}

@end
