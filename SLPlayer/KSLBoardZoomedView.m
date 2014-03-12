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
#import "KLDBGUtil.h"
#import "KSLProblem.h"

@implementation KSLBoardZoomedView
{
    UIPanGestureRecognizer *_panGr;
    UIPinchGestureRecognizer *_pinchGr;
    UITapGestureRecognizer *_tapGr;
//    KSLBoard *_board;
    CGFloat _x0;
    CGFloat _y0;
    CGFloat _pitch;
    NSMutableArray *_tracks;
    CGFloat _r;
    KSLNode *_prevNode;
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
    _tapGr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    
    [self addGestureRecognizer:_panGr];
    [self addGestureRecognizer:_pinchGr];
    [self addGestureRecognizer:_tapGr];
    _tracks = [NSMutableArray array];
    _r = 16;
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
        float margin = (KSLPROBLEM_MARGIN - KSLPROBLEM_BORDER_WIDTH) * _pitch;
        CGRect boardRect = CGRectMake(_x0 - margin, _y0 - margin,
                                      board.width  * _pitch + margin * 2,
                                      board.height * _pitch + margin * 2);
        CGContextFillRect(context, boardRect);
        
        CGContextSetFillColorWithColor(context,
                                       [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:0.1].CGColor);
        for (NSValue *val in _tracks) {
            CGPoint track = val.CGPointValue;
            CGContextFillEllipseInRect(context, CGRectMake(track.x - _r, track.y - _r, 2 * _r, 2 * _r));
        }
        
        [board drawImageWithContext:context origin:CGPointMake(_x0, _y0) pitch:_pitch
                      erasableColor:[UIColor blueColor].CGColor];
    }
}


/**
 * パンされた際のアクション
 */
- (IBAction)panned:(id)sender
{
    switch (_mode) {
        case KSLProblemViewModeScroll:{
            CGPoint translation = [_panGr translationInView:self];
            [_panGr setTranslation:CGPointZero inView:self];
            [self panZoomedArea:translation];
            break;
        }
        case KSLProblemViewModeInputLine:
        case KSLProblemViewModeErase:{
            UIGestureRecognizerState state = _panGr.state;
            if (state == UIGestureRecognizerStateBegan) {
                [_tracks removeAllObjects];
                _prevNode = nil;
                [_delegate stepBegan];
            }
            CGPoint track = [_panGr locationInView:self];
            [_tracks addObject:[NSValue valueWithCGPoint:track]];
            if (_mode == KSLProblemViewModeInputLine) {
                KSLNode *node = [self findNode:track];
                if (node && node != _prevNode) {
                    if (_prevNode) {
                        KLDBGPrint("node:%s-%s\n", node.description.UTF8String,
                                   _prevNode.description.UTF8String);
                        KSLEdge *edge = [_delegate.board getJointEdgeOfNodes:_prevNode and:node];
                        KLDBGPrint("edge:%s\n", edge.description.UTF8String);
                        if (edge && edge.status == KSLEdgeStatusUnset) {
                            KSLAction *action = [[KSLAction alloc] initWithType:KSLActionTypeEdgeStatus
                                        target:edge fromValue:KSLEdgeStatusUnset toValue:KSLEdgeStatusOn];
                            edge.status = KSLEdgeStatusOn;
                            [_delegate actionPerformed:action];
                        }
                    }
                    _prevNode = node;
                }
            } else {
                KSLEdge *edge = [self findEdge:track];
                if (edge && edge.status != KSLEdgeStatusUnset && !edge.fixed) {
                    KSLAction *action = [[KSLAction alloc] initWithType:KSLActionTypeEdgeStatus
                                        target:edge fromValue:edge.status toValue:KSLEdgeStatusUnset];
                    edge.status = KSLEdgeStatusUnset;
                    [_delegate actionPerformed:action];
                }
            }
            
            [self setNeedsDisplay];
            
            if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled) {
                [_delegate stepEnded];
                [self performSelector:@selector(clearTrackes) withObject:nil afterDelay:1];
            }
            break;
        }
        default:
            break;
    }

}

/**
 * ズームされた際のアクション
 */
- (IBAction)pinched:(id)sender
{
    CGFloat scale = _pinchGr.scale;
    [self zoomZoomedArea:scale];
}

/**
 * タップされた際のアクション
 */
- (IBAction)tapped:(id)sender
{
    CGPoint track = [_panGr locationInView:self];
    [_tracks addObject:[NSValue valueWithCGPoint:track]];
    switch (_mode) {
        case KSLProblemViewModeInputNumber:{
            KSLCell *cell = [self findCell:track];
            if (cell) {
                int oldNumber = cell.number;
                int newNumber = oldNumber == 3 ? -1 : oldNumber + 1;
                KSLAction *action = [[KSLAction alloc] initWithType:KSLActionTypeCellNumber
                                            target:cell fromValue:oldNumber toValue:newNumber];
                [cell changeNumber:newNumber];
                [_delegate actionPerformed:action];
            }
            break;
        }
        case KSLProblemViewModeInputLine:{
            KSLEdge *edge = [self findEdge:track];
            if (edge && edge.status == KSLEdgeStatusUnset) {
                KSLAction *action = [[KSLAction alloc] initWithType:KSLActionTypeEdgeStatus
                                        target:edge fromValue:edge.status toValue:KSLEdgeStatusOff];
                edge.status = KSLEdgeStatusOff;
                [_delegate actionPerformed:action];
            }
            break;
        }
        case KSLProblemViewModeErase:{
            KSLEdge *edge = [self findEdge:track];
            if (edge && edge.status != KSLEdgeStatusUnset && !edge.fixed) {
                KSLAction *action = [[KSLAction alloc] initWithType:KSLActionTypeEdgeStatus
                                        target:edge fromValue:edge.status toValue:KSLEdgeStatusUnset];
                edge.status = KSLEdgeStatusUnset;
                [_delegate actionPerformed:action];
            }
            break;
        }
        default:
            break;
    }
    [self setNeedsDisplay];
    [self performSelector:@selector(clearTrackes) withObject:nil afterDelay:1];
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

- (void)clearTrackes
{
    [_tracks removeAllObjects];
    _prevNode = nil;
    [self setNeedsDisplay];
}

- (void)calculateBoardParameter
{
    CGRect zoomed = _delegate.zoomedArea;
    CGFloat w = self.frame.size.width;
    _pitch = w / zoomed.size.width;
    
    _x0 = -_pitch * zoomed.origin.x;
    _y0 = -_pitch * zoomed.origin.y;
}

- (KSLNode *)findNode:(CGPoint)point
{
    KSLBoard *board = _delegate.board;
    CGFloat xp = (point.x - _x0) / _pitch;
    CGFloat yp = (point.y - _y0) / _pitch;
    int xi = (int)(xp + 0.5);
    int yi = (int)(yp + 0.5);
    xi = KLCGClumpInt(xi, 0, board.width - 1);
    yi = KLCGClumpInt(yi, 0, board.height - 1);
    
    CGFloat dx = (xp - xi) * _pitch;
    CGFloat dy = (yp - yi) * _pitch;
    if (dx * dx + dy * dy < _r * _r) {
        return [board nodeAtX:xi andY:yi];
    }
    return nil;
}

- (KSLCell *)findCell:(CGPoint)point
{
    KSLBoard *board = _delegate.board;
    CGFloat xp = (point.x - _x0) / _pitch;
    CGFloat yp = (point.y - _y0) / _pitch;
    int xi = (int)xp;
    int yi = (int)yp;
    xi = KLCGClumpInt(xi, 0, board.width - 1);
    yi = KLCGClumpInt(yi, 0, board.height - 1);
    
    CGFloat dx = (xp - (xi + 0.5)) * _pitch;
    CGFloat dy = (yp - (yi + 0.5)) * _pitch;
    if (dx * dx + dy * dy < _r * _r) {
        return [board cellAtX:xi andY:yi];
    }
    return nil;
}

- (KSLEdge *)findEdge:(CGPoint)point
{
    KSLBoard *board = _delegate.board;
    CGFloat xp = (point.x - _x0) / _pitch;
    CGFloat yp = (point.y - _y0) / _pitch;
    int xi = (int)(xp + 0.5);
    int yi = (int)(yp + 0.5);
    xi = KLCGClumpInt(xi, 0, board.width - 1);
    yi = KLCGClumpInt(yi, 0, board.height - 1);
    
    CGFloat dx = (xp - xi) * _pitch;
    CGFloat dy = (yp - yi) * _pitch;
    
    if (abs(dx) < abs(dy)) {
        yi = (int)yp;
        dy = (yp - (yi + 0.5)) * _pitch;
        if (dx * dx + dy * dy < _r * _r) {
            return [board vEdgeAtX:xi andY:yi];
        }
    } else {
        xi = (int)xp;
        dx = (xp - (xi + 0.5)) * _pitch;
        if (dx * dx + dy * dy < _r * _r) {
            return [board hEdgeAtX:xi andY:yi];
        }
    }
    return nil;
}

@end
