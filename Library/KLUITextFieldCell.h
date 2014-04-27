//
//  PRTextFieldCell.h
//  PDFReader
//
//  Created by KO on 12/01/16.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * テキスト入力欄となるセル
 */
@interface KLUITextFieldCell : UITableViewCell

// TextFieldコントロール
@property (nonatomic, readonly) UITextField* textField;

@end
