//
//  KSLProbremView.m
//  SLPlayer
//
//  Created by KO on 2014/01/02.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import "KSLBoardZoomedView.h"
#import "KSLProblemViewDelegate.h"
#import "KSLBoard.h"
#import "KLCGPointUtil.h"
#import "KLCGUtil.h"

@implementation KSLBoardZoomedView
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
    CGContextSetFillColorWithColor(context, [UIColor lightGrayColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, w, h));
    
    KSLBoard *board = _delegate.board;
    if (board) {
        [self calculateBoardParameter];
        CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
        CGRect boardRect = CGRectMake(_x0 - _pitch, _y0 - _pitch,
                                      (board.width + KSLPROBLEM_MARGIN * 2) * _pitch,
                                      (board.height + KSLPROBLEM_MARGIN * 2) * _pitch);
        CGContextFillRect(context, boardRect);
        
        [board drawImageWithContext:context origin:CGPointMake(_x0, _y0) pitch:_pitch
                      erasableColor:[UIColor blueColor].CGColor];
    }
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
    [self calculateBoardParameter];
    [self setZoomedAreaWithRect:CGRectOffset(_delegate.zoomedArea,
                                             -translation.x / _pitch, -translation.y / _pitch)];
}

- (void)zoomZoomedArea:(CGFloat)scale
{
    [self calculateBoardParameter];

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

- (void)calculateBoardParameter
{
    CGRect zoomed = _delegate.zoomedArea;
    CGFloat w = self.frame.size.width;
    _pitch = w / zoomed.size.width;
    
    _x0 = -_pitch * zoomed.origin.x;
    _y0 = -_pitch * zoomed.origin.y;
}

@end
