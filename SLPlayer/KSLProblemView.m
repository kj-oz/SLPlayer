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
#import "KSLProblem.h"

@implementation KSLProblemView
{
    // 各種ジェスチャーリコグナイザ
    UIPanGestureRecognizer *_panGr;
    UIPinchGestureRecognizer *_pinchGr;
    UITapGestureRecognizer *_tap1Gr;
    UITapGestureRecognizer *_tap2Gr;
    UILongPressGestureRecognizer *_lpGr;
    
    // ドラッグ、パンの軌跡
    NSMutableArray *_tracks;
    
    // タップ位置にノードが含まれているかどうかの判定の半径
    CGFloat _r;
    
    // ドラッグ時の直前にたどったノード
    KSLNode *_prevNode;
    
    // ロングプレス時のスクロールの速度
    // TODO スクロールはアニメーションを使用するべき
    CGFloat _scrollStep;
    
    // ズーム中かどうか
    BOOL _zoomed;
    
    // 画面座標系でのズーム時の問題原点（左上）の座標と点の間隔
    CGFloat _zx0;
    CGFloat _zy0;
    CGFloat _zpitch;
    
    // 画面座標系での全体表示時の問題原点（左上）の座標と点の間隔
    CGFloat _ax0;
    CGFloat _ay0;
    CGFloat _apitch;
    
    // 問題座標系でのズーム時の表示領域
    CGRect _zoomedArea;
    
    // 問題座標系でのズームエリアの可動範囲
    CGRect _zoomableArea;
    
    //
    CGFloat _dx;
    CGFloat _dy;
    NSTimer *_timer;
}

#pragma mark - 初期化

- (void)awakeFromNib
{
    // NOTE この段階ではまだdelegateは設定されていない
    _panGr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)];
    _pinchGr = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinched:)];
    _tap1Gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped1:)];
    _tap2Gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped2:)];
    _tap2Gr.numberOfTouchesRequired = 2;
    _lpGr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
    
    [self addGestureRecognizer:_panGr];
    [self addGestureRecognizer:_pinchGr];
    [self addGestureRecognizer:_tap1Gr];
    [self addGestureRecognizer:_tap2Gr];
    [self addGestureRecognizer:_lpGr];
    _tracks = [NSMutableArray array];
}

#pragma mark - プロパティ

- (void)setBoard:(KSLBoard *)board
{
    NSLog(@"%@", board);
    if (!board) {
        NSLog(@"BUG!");
    }
    _board = board;
    [self calculateOverallParameter];
    [self calculateZoomedParameter];
    
    // 拡大サイズでも画面より小さい場合は常に拡大
    // TODO ビューの初期状態の記録・復元
    _zoomed = (_apitch == _zpitch);
    
    // 初期拡大エリア
    CGFloat zoomedW = self.frame.size.width / _zpitch;
    CGFloat zoomedH = self.frame.size.height / _zpitch;
    [self setZoomedAreaWithRect:
                   CGRectMake(_zoomableArea.origin.x, _zoomableArea.origin.y, zoomedW, zoomedH)];
}

/**
 * 全体表示時の位置や点の間隔を予め計算しておく
 */
- (void)calculateOverallParameter
{
    CGFloat w = self.frame.size.width;
    CGFloat h = self.frame.size.height;
    CGFloat pitchH = w / (_board.width + 2 * KSLPROBLEM_MARGIN);
    CGFloat pitchV = h / (_board.height + 2 * KSLPROBLEM_MARGIN);
    if (pitchH > KSLPROBLEM_TOUCHABLE_PITCH && pitchV > KSLPROBLEM_TOUCHABLE_PITCH) {
        // 実際には常にズーム中として扱うため使用されない
        _apitch = KSLPROBLEM_TOUCHABLE_PITCH;
        _ax0 = (w - _apitch * _board.width) / 2;
        _ay0 = (h - _apitch * _board.height) / 2;
    } else if (pitchH < pitchV) {
        _apitch = pitchH;
        _ax0 = _apitch * KSLPROBLEM_MARGIN;
        _ay0 = (h - _apitch * _board.height) / 2;
    } else {
        _apitch = pitchV;
        _ay0 = _apitch * KSLPROBLEM_MARGIN;
        _ax0 = (w - _apitch * _board.width) / 2;
    }
}

/**
 * ズーム時の位置や点の間隔を予め計算しておく
 */
- (void)calculateZoomedParameter
{
    _zpitch = KSLPROBLEM_TOUCHABLE_PITCH;
    _r = _zpitch * 0.5;
    _scrollStep = _zpitch * 0.3;

    CGFloat w = self.frame.size.width / _zpitch;
    CGFloat h = self.frame.size.height / _zpitch;
    
    CGFloat zxmin;
    CGFloat zxmax;
    CGFloat zymin;
    CGFloat zymax;
    
    if (_board.width + 2 * KSLPROBLEM_MARGIN < w) {
        zxmin = zxmax = (w - _board.width) / 2;
    } else {
        zxmin = w - (_board.width + KSLPROBLEM_MARGIN);
        zxmax = KSLPROBLEM_MARGIN;
    }
    
    if (_board.height + 2 * KSLPROBLEM_MARGIN < h) {
        zymin = zymax = (h - _board.height) / 2;
    } else {
        zymin = h - (_board.height + KSLPROBLEM_MARGIN);
        zymax = KSLPROBLEM_MARGIN;
    }
    
    _zoomableArea = CGRectMake(-zxmax, -zymax, zxmax + w - zxmin, zymax + h - zymin);
}

/**
 * 拡大表示領域を設定する
 */
- (void)setZoomedAreaWithRect:(CGRect)rect
{
    _zoomedArea = KLCGClumpRect(rect, _zoomableArea);
    _zx0 = -_zoomedArea.origin.x * _zpitch;
    _zy0 = -_zoomedArea.origin.y * _zpitch;
}

#pragma mark - 描画

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat w = self.frame.size.width;
    CGFloat h = self.frame.size.height;
    CGContextSetFillColorWithColor(context, [UIColor lightGrayColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, w, h));
    
    if (_board) {
        if (_zoomed) {
            CGContextSetFillColorWithColor(context, [UIColor lightGrayColor].CGColor);
            CGContextFillRect(context, CGRectMake(0, 0, w, h));

            CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
            
            float margin = (KSLPROBLEM_MARGIN - KSLPROBLEM_BORDER_WIDTH) * _zpitch;
            CGRect boardRect = CGRectMake(_zx0 - margin, _zy0 - margin,
                                          _board.width  * _zpitch + margin * 2,
                                          _board.height * _zpitch + margin * 2);
            CGContextFillRect(context, boardRect);
            
            // タッチの余韻描画
            CGContextSetFillColorWithColor(context,
                                        [UIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:0.05].CGColor);
            for (NSValue *val in _tracks) {
                CGPoint track = val.CGPointValue;
                CGContextFillEllipseInRect(context, CGRectMake(track.x - _r, track.y - _r, 2 * _r, 2 * _r));
            }
            
            [_board drawImageWithContext:context origin:CGPointMake(_zx0, _zy0) pitch:_zpitch
                          erasableColor:[UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0].CGColor];
        } else {
            CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
            CGContextFillRect(context, CGRectMake(0, 0, w, h));

            [_board drawImageWithContext:context origin:CGPointMake(_ax0, _ay0) pitch:_apitch
                          erasableColor:[UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0].CGColor];
            
            CGContextSetFillColorWithColor(context,
                                           [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:0.2].CGColor);
            CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
            
            CGRect rect = [self zoomedAreaInView];
            CGContextFillRect(context, rect);
            CGContextStrokeRect(context, rect);
        }
    }
}

/**
 * 拡大領域の表示座標系上での位置を得る
 * @return 拡大領域の表示座標系上での位置
 */
- (CGRect)zoomedAreaInView
{
    CGFloat x = _ax0 + _zoomedArea.origin.x * _apitch;
    CGFloat y = _ay0 + _zoomedArea.origin.y * _apitch;
    CGFloat w = _zoomedArea.size.width * _apitch;
    CGFloat h = _zoomedArea.size.height * _apitch;
    
    return CGRectMake(x, y, w, h);
}

#pragma mark - ジェスチャー

/**
 * パン：拡大時-線、全体表示時-ズーム位置移動
 */
- (IBAction)panned:(id)sender
{
    if (_zoomed) {
        UIGestureRecognizerState state = _panGr.state;
        if (state == UIGestureRecognizerStateBegan) {
            [_tracks removeAllObjects];
            _prevNode = nil;
            [_delegate stepBegan];
            
            CGPoint translation = [_panGr translationInView:self];
            CGPoint track = [_panGr locationInView:self];
            track = KLCGPointSubtract(track, translation);
            [_tracks addObject:[NSValue valueWithCGPoint:track]];
            KSLNode *node = [self findNode:track];
            if (node) {
                _prevNode = node;
            }
        }
        CGPoint track = [_panGr locationInView:self];
        [_tracks addObject:[NSValue valueWithCGPoint:track]];
        
        KSLNode *node = [self findNode:track];
        if (node && node != _prevNode) {
            if (_prevNode) {
                KLDBGPrint("node:%s-%s\n", node.description.UTF8String,
                           _prevNode.description.UTF8String);
                KSLEdge *edge = [_board getJointEdgeOfNodes:_prevNode and:node];
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
        
        [self setNeedsDisplay];
        
        if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled) {
            [_delegate stepEnded];
            [self performSelector:@selector(clearTrackes) withObject:nil afterDelay:1];
        }
    } else {
        CGPoint translation = [_panGr translationInView:self];
        [_panGr setTranslation:CGPointZero inView:self];
        CGPoint location = KLCGPointSubtract([_panGr locationInView:self], translation);
        CGRect zoomedArea = [self zoomedAreaInView];
        
        if (CGRectContainsPoint(zoomedArea, location)) {
            [self setZoomedAreaWithRect:
                    CGRectOffset(_zoomedArea, translation.x / _apitch, translation.y / _apitch)];
            [self setNeedsDisplay];
        }
    }
}

/**
 * ピンチ：ズームの切替
 */
- (IBAction)pinched:(id)sender
{
    CGFloat scale = _pinchGr.scale;
    if (scale < 1 && _zoomed) {
        if (_apitch != _zpitch) {
            _zoomed = NO;
        } else {
            return;
        }
    } else if (scale > 1 && !_zoomed) {
        // TODO ズーム位置の計算
        _zoomed = YES;
    } else {
        return;
    }
    [self setNeedsDisplay];
}

/**
 * タップ：×またはクリア
 */
- (IBAction)tapped1:(id)sender
{
    // Note: tapのイベントのstateは常に3になる
    if (_zoomed) {
        CGPoint track = [_tap1Gr locationInView:self];
        [_tracks addObject:[NSValue valueWithCGPoint:track]];
        switch (_mode) {
            case KSLProblemViewModeInputNumber:{
                KSLCell *cell = [self findCell:track];
                if (!cell) {
                    break;
                }
                NSInteger oldNumber = cell.number;
                NSInteger newNumber = oldNumber == 3 ? -1 : oldNumber + 1;
                KSLAction *action = [[KSLAction alloc] initWithType:KSLActionTypeCellNumber
                                                             target:cell fromValue:oldNumber toValue:newNumber];
                [cell changeNumber:newNumber];
                [_delegate actionPerformed:action];
                break;
            }
            case KSLProblemViewModeInputLine:{
                KSLEdge *edge = [self findEdge:track];
                if (!edge || edge.fixed) {
                    break;
                }
                KSLEdgeStatus oldStatus = edge.status;
                KSLEdgeStatus newStatus = oldStatus == KSLEdgeStatusUnset ?
                KSLEdgeStatusOff : KSLEdgeStatusUnset;
                KSLAction *action = [[KSLAction alloc] initWithType:KSLActionTypeEdgeStatus
                                                             target:edge fromValue:oldStatus toValue:newStatus];
                edge.status = newStatus;
                [_delegate actionPerformed:action];
                break;
            }
            default:
                break;
        }
        [self performSelector:@selector(clearTrackes) withObject:nil afterDelay:1];
    } else {
        // TODO ズーム位置の計算
        _zoomed = YES;
    }
    [self setNeedsDisplay];
}

/**
 * 2本指タップ：ズームの切替
 */
- (IBAction)tapped2:(id)sender
{
    if (_zoomed) {
        if (_apitch != _zpitch) {
            _zoomed = NO;
        } else {
            return;
        }
    } else {
        // TODO ズーム位置の計算
        _zoomed = YES;
    }
    [self setNeedsDisplay];
}

/**
 * ロングプレス：スクロール
 */
- (IBAction)longPressed:(id)sender
{
    if (_zoomed) {
        UIGestureRecognizerState state = _lpGr.state;
        KLDBGPrint("lp-state:%ld\n", (long)state);
        if (state == UIGestureRecognizerStateBegan) {
            CGPoint point = [_lpGr locationInView:self];
            _dx = 0;
            _dy = 0;
            CGFloat xp = point.x / self.bounds.size.width;
            if (xp < 0.25) {
                _dx = 1;
            } else if (xp > 0.75) {
                _dx = -1;
            }
            CGFloat yp = point.y / self.bounds.size.height;
            if (yp < 0.25) {
                _dy = 1;
            } else if (yp > 0.75) {
                _dy = -1;
            }
            if (_dx != 0 || _dy != 0) {
                _timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                        target:self selector:@selector(autoScroll) userInfo:nil repeats:YES];
            }
        } else if (state == UIGestureRecognizerStateEnded) {
            [_timer invalidate];
        }
    }
}

- (void)autoScroll
{
    [self panZoomedArea:CGPointMake(_dx * _scrollStep, _dy * _scrollStep)];
    [self setNeedsDisplay];
}

/**
 * 拡大領域を移動する
 * @param translation 拡大領域を移動する量（表示座標系）
 */
- (void)panZoomedArea:(CGPoint)translation
{
    [self setZoomedAreaWithRect:CGRectOffset(_zoomedArea,
                                             -translation.x / _zpitch, -translation.y / _zpitch)];
}

/**
 * 画面に表示中の軌跡をクリアする
 */
- (void)clearTrackes
{
    [_tracks removeAllObjects];
    _prevNode = nil;
    [self setNeedsDisplay];
}

#pragma mark - ヘルパメソッド

- (KSLNode *)findNode:(CGPoint)point
{
    CGFloat xp = (point.x - _zx0) / _zpitch;
    CGFloat yp = (point.y - _zy0) / _zpitch;
    NSInteger xi = (NSInteger)(xp + 0.5);
    NSInteger yi = (NSInteger)(yp + 0.5);
    xi = KLCGClumpInt(xi, 0, _board.width);
    yi = KLCGClumpInt(yi, 0, _board.height);
    
    CGFloat dx = (xp - xi) * _zpitch;
    CGFloat dy = (yp - yi) * _zpitch;
    if (dx * dx + dy * dy < _r * _r) {
        return [_board nodeAtX:xi andY:yi];
    }
    return nil;
}

- (KSLCell *)findCell:(CGPoint)point
{
    CGFloat xp = (point.x - _zx0) / _zpitch;
    CGFloat yp = (point.y - _zy0) / _zpitch;
    NSInteger xi = (NSInteger)xp;
    NSInteger yi = (NSInteger)yp;
    xi = KLCGClumpInt(xi, 0, _board.width - 1);
    yi = KLCGClumpInt(yi, 0, _board.height - 1);
    
    CGFloat dx = (xp - (xi + 0.5)) * _zpitch;
    CGFloat dy = (yp - (yi + 0.5)) * _zpitch;
    if (dx * dx + dy * dy < _r * _r) {
        return [_board cellAtX:xi andY:yi];
    }
    return nil;
}

- (KSLEdge *)findEdge:(CGPoint)point
{
    CGFloat xp = (point.x - _zx0) / _zpitch;
    CGFloat yp = (point.y - _zy0) / _zpitch;
    NSInteger xi = (NSInteger)(xp + 0.5);
    NSInteger yi = (NSInteger)(yp + 0.5);
    xi = KLCGClumpInt(xi, 0, _board.width);
    yi = KLCGClumpInt(yi, 0, _board.height);
    
    CGFloat dx = (xp - xi) * _zpitch;
    CGFloat dy = (yp - yi) * _zpitch;
    
    if (abs(dx) < abs(dy)) {
        yi = (NSInteger)yp;
        if (yi == _board.height) yi--;
        dy = (yp - (yi + 0.5)) * _zpitch;
        if (dx * dx + dy * dy < _r * _r) {
            KLDBGPrint("VE:%ld/%ld (%.1f/%.1f)\n", (long)xi, (long)yi, xp, yp);
            return [_board vEdgeAtX:xi andY:yi];
        }
    } else {
        xi = (NSInteger)xp;
        if (xi == _board.width) xi--;
        dx = (xp - (xi + 0.5)) * _zpitch;
        if (dx * dx + dy * dy < _r * _r) {
            KLDBGPrint("HE:%ld/%ld (%.1f/%.1f)\n", (long)xi, (long)yi, xp, yp);
            return [_board hEdgeAtX:xi andY:yi];
        }
    }
    return nil;
}

@end
