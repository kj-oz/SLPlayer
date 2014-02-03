//
//  KSLProbremView.m
//  SLPlayer
//
//  Created by KO on 2014/01/02.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import "KSLProblemView.h"
#import "KSLProblemViewDelegate.h"
#import "KSLBoard.h"
#import "KLCGPointUtil.h"
#import "KLCGUtil.h"
#import "KLDBGUtil.h"

@implementation KSLProblemView
{
    UIPanGestureRecognizer *_panGr;
    UIPinchGestureRecognizer *_pinchGr;
    KSLBoard *_board;
    CGFloat _x0;
    CGFloat _y0;
    CGFloat _pitch;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
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
    _panGr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)];
    _pinchGr = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinched:)];
    [self addGestureRecognizer:_panGr];
    [self addGestureRecognizer:_pinchGr];
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
        
        CGContextSetFillColorWithColor(context, [UIColor darkGrayColor].CGColor);
        CGFloat margin = KSLPROBLEM_MARGIN * _pitch;
        CGFloat border = KSLPROBLEM_BORDER_WIDTH * _pitch;
        CGFloat x1 = _x0 + board.width * _pitch;
        CGFloat y1 = _y0 + board.height * _pitch;
        CGContextFillRect(context, CGRectMake(_x0 - margin, _y0 - margin,
                                              border, board.height * _pitch + 2.0 * margin));
        CGContextFillRect(context, CGRectMake(x1 + margin - border, _y0 - margin,
                                              border, board.height * _pitch + 2.0 * margin));
        CGContextFillRect(context, CGRectMake(_x0 - margin, _y0 - margin,
                                              board.width * _pitch + 2.0 * margin, border));
        CGContextFillRect(context, CGRectMake(_x0 - margin, y1 + margin - border,
                                              board.width * _pitch + 2.0 * margin, border));
    }
    
    CGContextSetLineWidth(context, 2.0);
    CGContextSetStrokeColorWithColor(context, [UIColor darkGrayColor].CGColor);
    CGContextStrokeRect(context, CGRectMake(1, 1, w-2, h-2));
}

- (IBAction)panned:(id)sender
{
    CGPoint translation = [_panGr translationInView:self];
    [self panZoomedArea:translation];
}

- (IBAction)pinched:(id)sender
{
    CGFloat scale = _pinchGr.scale;
    [self zoomZoomedArea:scale];
}

- (void)panZoomedArea:(CGPoint)translation
{
    [self calculateBoardOrigin];
    [self setZoomedAreaWithRect:CGRectOffset(_delegate.zoomedArea,
                                             -translation.x / _pitch, -translation.y / _pitch)];
}

- (void)zoomZoomedArea:(CGFloat)scale
{
    [self calculateBoardOrigin];

    CGFloat p = KLCGClumpValue(_pitch * scale, KSLPROBLEM_MINIMUM_PITCH, KSLPROBLEM_MAXIMUM_PITCH);
    CGFloat w = self.frame.size.width / p;
    CGFloat h = self.frame.size.height / p;

    CGFloat cx = CGRectGetMidX(_delegate.zoomedArea);
    CGFloat cy = CGRectGetMidY(_delegate.zoomedArea);
    
    CGFloat x = cx - w / 2;
    CGFloat y = cy - h / 2;
    
    [self setZoomedAreaWithRect:CGRectMake(x, y, w, h)];
}

- (void)setZoomedAreaWithRect:(CGRect)rect
{
    _delegate.zoomedArea = KLCGClumpRect(rect, _delegate.problemArea);
}

- (void)calculateBoardOrigin
{
    CGRect zoomed = _delegate.zoomedArea;
    CGFloat w = self.frame.size.width;
    _pitch = w / zoomed.size.width;
    
    _x0 = -_pitch * zoomed.origin.x;
    _y0 = -_pitch * zoomed.origin.y;
}

@end
