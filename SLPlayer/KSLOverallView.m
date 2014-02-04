//
//  KSLOverallView.m
//  SLPlayer
//
//  Created by KO on 2014/01/02.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import "KSLOverallView.h"
#import "KSLProblemViewDelegate.h"
#import "KSLBoard.h"
#import "KLCGPointUtil.h"
#import "KLCGUtil.h"

@implementation KSLOverallView
{
    UIPanGestureRecognizer *_panGr;
    KSLBoard *_board;
    CGFloat _x0;
    CGFloat _y0;
    CGFloat _pitch;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _panGr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    KLDBGPrintMethodName("> ");
    return [super initWithCoder:aDecoder];
}

- (void)awakeFromNib
{
//    KSLOverallView *view = (KSLOverallView *)[[[NSBundle mainBundle] loadNibNamed:@"KSLOverallView"
//                                                                owner:nil options:nil] lastObject];
//    [self addSubview:view];
    _panGr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)];
    [self addGestureRecognizer:_panGr];
    KLDBGPrintMethodName("> ");
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat w = self.frame.size.width;
    CGFloat h = self.frame.size.height;
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, w, h));
    
    KSLBoard *board = _delegate.board;
    if (board) {
        [self calculateBoardOrigin];
        [board drawImageWithContext:context origin:CGPointMake(_x0, _y0) pitch:_pitch
                                erasableColor:[UIColor blueColor].CGColor];
        
        CGContextSetFillColorWithColor(context,
                        [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:0.2].CGColor);
        CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
        
        CGRect rect = [self zoomedArea];
        CGContextFillRect(context, rect);
        CGContextStrokeRect(context, rect);
    }
}

- (IBAction)panned:(id)sender
{
    CGPoint translation = [_panGr translationInView:self];
    CGPoint location = KLCGPointSubtract([_panGr locationInView:self], translation);
    CGRect zoomedArea = [self zoomedArea];
    
    if (CGRectContainsPoint(zoomedArea, location)) {
        [self setZoomedArea:CGRectOffset(zoomedArea, translation.x, translation.y)];
    }
}

- (CGRect)zoomedArea
{
    [self calculateBoardOrigin];
    
    CGRect zoomedArea = _delegate.zoomedArea;
    CGFloat x = _x0 + zoomedArea.origin.x * _pitch;
    CGFloat y = _y0 + zoomedArea.origin.y * _pitch;
    CGFloat w = zoomedArea.size.width * _pitch;
    CGFloat h = zoomedArea.size.height * _pitch;
    return CGRectMake(x, y, w, h);
}

- (void)setZoomedArea:(CGRect)rectByPixel
{
    [self calculateBoardOrigin];
    
    CGFloat x = (rectByPixel.origin.x - _x0) / _pitch;
    CGFloat y = (rectByPixel.origin.y - _y0) / _pitch;
    CGFloat w = rectByPixel.size.width / _pitch;
    CGFloat h = rectByPixel.size.height / _pitch;
    _delegate.zoomedArea = KLCGClumpRect(CGRectMake(x, y, w, h), _delegate.problemArea);
}

- (void)calculateBoardOrigin
{
    if (_delegate.board != _board) {
        KSLBoard *board = _delegate.board;
        CGFloat w = self.frame.size.width;
        CGFloat h = self.frame.size.height;
        CGFloat pitchH = w / (board.width + 2 * KSLPROBLEM_MARGIN);
        CGFloat pitchV = h / (board.height + 2 * KSLPROBLEM_MARGIN);
        _pitch = MIN(pitchH, pitchV);
        
        _x0 = (w - _pitch * board.width) / 2;
        _y0 = (h - _pitch * board.height) / 2;
    }
}

@end
