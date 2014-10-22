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
    
    // ドラッグ時の直前にたどった辺（微小のドラッグをタップとして扱うため）
    KSLEdge *_prevEdge;
    
    // ロングプレス時のスクロールの速度
    // TODO スクロールはアニメーションを使用するべき
    CGFloat _scrollStep;
    
    // ズーム中かどうか
    BOOL _zoomed;
    
    // 回転しているかどうか
    // 問題の縦横比と画面の縦横比の方向が一致していなければ回転
    // 問題が正方形の場合縦向きとして扱う
    BOOL _rotated;
    
    // 画面座標系でのズーム時の問題原点（左上）の座標と点の間隔
    CGFloat _zx0;
    CGFloat _zy0;
    CGFloat _zpitch;
    
    // 画面座標系での全体表示時の問題原点（左上）の座標と点の間隔
    CGFloat _ax0;
    CGFloat _ay0;
    CGFloat _apitch;
    
    // 問題座標系でのズームエリアの可動範囲
    CGRect _zoomableArea;
    
    //
    BOOL _fixH;
    BOOL _fixV;
    
    // ロングプレス時の連続スクロールの定義
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
    
    // 定数
    _zpitch = KSLPROBLEM_TOUCHABLE_PITCH;
    _r = _zpitch * 0.5;
    _scrollStep = _zpitch * 0.2;
}

#pragma mark - プロパティ

- (void)setBoard:(KSLBoard *)board
{
    NSLog(@"%@", board);
    if (!board) {
        NSLog(@"BUG!");
    }
    _board = board;
    _rotated = [self checkRotation];
    
    // 拡大サイズでも画面より小さい場合は常に拡大
    _zoomed = YES;
    [self adjustZoomedArea];
}

#pragma mark - 描画

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat w = self.frame.size.width;
    CGFloat h = self.frame.size.height;
    
    if (_board) {
        BOOL rotated = [self checkRotation];
        if (rotated != _rotated) {
            _rotated = rotated;
            [self adjustZoomedArea];
        }
        BOOL editing = _mode == KSLProblemViewModeInputNumber;
        if (_zoomed) {
            CGContextSetFillColorWithColor(context, [UIColor lightGrayColor].CGColor);
            CGContextFillRect(context, CGRectMake(0, 0, w, h));

            CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
            
            CGRect boardRect;
            float margin = (KSLPROBLEM_MARGIN - KSLPROBLEM_BORDER_WIDTH) * _zpitch;
            if (_rotated) {
                boardRect = CGRectMake(_zx0 - margin, _zy0 - _board.width * _zpitch - margin,
                                        _board.height * _zpitch + margin * 2,
                                        _board.width * _zpitch + margin * 2);
            } else {
                boardRect = CGRectMake(_zx0 - margin, _zy0 - margin,
                                        _board.width * _zpitch + margin * 2,
                                        _board.height * _zpitch + margin * 2);
            }
            CGContextFillRect(context, boardRect);
            
            // タッチの余韻描画
            CGContextSetFillColorWithColor(context,
                                        [UIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:0.03].CGColor);
            for (NSValue *val in _tracks) {
                CGPoint track = val.CGPointValue;
                CGContextFillEllipseInRect(context, CGRectMake(track.x - _r, track.y - _r, 2 * _r, 2 * _r));
            }
            
            [_board drawImageWithContext:context origin:CGPointMake(_zx0, _zy0) pitch:_zpitch rotate:_rotated
                           erasableColor:[UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0].CGColor
                               isEditing:editing];
        } else {
            CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
            CGContextFillRect(context, CGRectMake(0, 0, w, h));

            [_board drawImageWithContext:context origin:CGPointMake(_ax0, _ay0) pitch:_apitch rotate:_rotated
                           erasableColor:[UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0].CGColor
                               isEditing:editing];
            
            CGContextSetFillColorWithColor(context,
                                           [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:0.1].CGColor);
            CGContextSetStrokeColorWithColor(context,
                                           [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.2].CGColor);
            
            CGRect rect = [self zoomedAreaInView];
            CGContextFillRect(context, rect);
            CGContextStrokeRect(context, rect);
        }
    }
}

#pragma mark - プライベートメソッド（ジェスチャー）

/**
 * パン：拡大時-線、全体表示時-ズーム位置移動
 */
- (IBAction)panned:(id)sender
{
    if (_zoomed) {
        if (_mode == KSLProblemViewModeInputLine) {
            UIGestureRecognizerState state = _panGr.state;
            if (state == UIGestureRecognizerStateBegan) {
                KLDBGPrint(">>START\n");
                [_tracks removeAllObjects];
                _prevNode = nil;
                [_delegate stepBegan];
                
                CGPoint translation = [_panGr translationInView:self];
                CGPoint track = [_panGr locationInView:self];
                track = KLCGPointSubtract(track, translation);
                [_tracks addObject:[NSValue valueWithCGPoint:track]];
                KSLNode *node = [self findNode:track];
                KLDBGPrint("node0:%s\n", node ? node.description.UTF8String : "(nil)");
                if (node) {
                    _prevNode = node;
                }
                _prevEdge = [self findEdge:track];
            }
            CGPoint track = [_panGr locationInView:self];
            [_tracks addObject:[NSValue valueWithCGPoint:track]];
            
            KSLNode *node = [self findNode:track];
            KLDBGPrint("node:%s-%s\n", node ? node.description.UTF8String : "(nil)",
                       _prevNode ? _prevNode.description.UTF8String : "(nil)");
            if (node && node != _prevNode) {
                if (_prevNode) {
                    KSLEdge *edge = [_board getJointEdgeOfNodes:_prevNode and:node];
                    KLDBGPrint("> edge:%s\n", edge ? edge.description.UTF8String : "(nil)");
                    if (edge && edge.status == KSLEdgeStatusUnset) {
                        KSLAction *action = [[KSLAction alloc] initWithType:KSLActionTypeEdgeStatus
                                    target:edge fromValue:KSLEdgeStatusUnset toValue:KSLEdgeStatusOn];
                        edge.status = KSLEdgeStatusOn;
                        [_delegate actionPerformed:action];
                        _prevEdge = nil;
                    }
                }
                _prevNode = node;
            }
            KSLEdge *edge = [self findEdge:track];
            if (edge && edge != _prevEdge) {
                _prevEdge = nil;
            }
            
            [self setNeedsDisplay];
            if (state == UIGestureRecognizerStateEnded && _prevEdge && edge && !edge.fixed) {
                [self tapEdge:edge];
            }
            if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled) {
                [_delegate stepEnded];
                [self performSelector:@selector(clearTrackes) withObject:nil afterDelay:1];
            }
        }
    } else {
        CGPoint translation = [_panGr translationInView:self];
        [_panGr setTranslation:CGPointZero inView:self];
        CGPoint location = KLCGPointSubtract([_panGr locationInView:self], translation);
        CGRect rect = [self zoomedAreaInView];
        
        if (CGRectContainsPoint(rect, location)) {
            CGRect zoomedArea = _delegate.zoomedArea;
            if (_rotated) {
                [self setZoomedAreaWithRect:
                    CGRectOffset(zoomedArea, -translation.y / _apitch, translation.x / _apitch)];
            } else {
                [self setZoomedAreaWithRect:
                    CGRectOffset(zoomedArea, translation.x / _apitch, translation.y / _apitch)];
            }
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
                [self tapEdge:edge];
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
 * 辺上をタップした際の処理（微小パンの場合にもこの処理が呼ばれる）
 * @param edge 辺
 */
- (void)tapEdge:(KSLEdge *)edge
{
    KSLEdgeStatus oldStatus = edge.status;
    KSLEdgeStatus newStatus = oldStatus == KSLEdgeStatusUnset ?
    KSLEdgeStatusOff : KSLEdgeStatusUnset;
    KSLAction *action = [[KSLAction alloc] initWithType:KSLActionTypeEdgeStatus
                                                 target:edge fromValue:oldStatus toValue:newStatus];
    edge.status = newStatus;
    [_delegate actionPerformed:action];
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
            CGFloat xp = point.x;
            if (xp < 100) {
                _dx = 1;
            } else if (xp > self.bounds.size.width - 100) {
                _dx = -1;
            }
            CGFloat yp = point.y;
            if (yp < 100) {
                _dy = 1;
            } else if (yp > self.bounds.size.height - 100) {
                _dy = -1;
            }
            if (_dx != 0 || _dy != 0) {
                _timer = [NSTimer scheduledTimerWithTimeInterval:0.02
                        target:self selector:@selector(autoScroll) userInfo:nil repeats:YES];
            }
        } else if (state == UIGestureRecognizerStateEnded) {
            [_timer invalidate];
        }
    }
}

/**
 * Timerから呼び出される自動スクロール処理
 */
- (void)autoScroll
{
    [self panZoomedArea:CGPointMake(_dx * _scrollStep, _dy * _scrollStep)];
    [self setNeedsDisplay];
}

#pragma mark - プライベートメソッド（表示領域）

- (void)adjustZoomedArea
{
    [self calculateOverallParameter];
    [self calculateZoomedParameter];
    
    CGRect zoomedArea = _delegate.zoomedArea;
    CGFloat cx = CGRectGetMidX(zoomedArea);
    CGFloat cy = CGRectGetMidY(zoomedArea);
    
    CGFloat zoomedW;
    CGFloat zoomedH;
    if (_rotated) {
        zoomedW = self.frame.size.height / _zpitch;
        zoomedH = self.frame.size.width / _zpitch;
    } else {
        zoomedW = self.frame.size.width / _zpitch;
        zoomedH = self.frame.size.height / _zpitch;
    }
    
    CGFloat x0 = cx - 0.5 * zoomedW;
    CGFloat y0 = cy - 0.5 * zoomedH;
    if (!_fixH) {
        if (x0 < 0) {
            x0 = -KSLPROBLEM_MARGIN;
        } else if (x0 + zoomedW > _board.width) {
            x0 = _board.width + KSLPROBLEM_MARGIN - zoomedW;
        }
    }
    if (!_fixV) {
        if (y0 < 0) {
            y0 = -KSLPROBLEM_MARGIN;
        } else if (y0 + zoomedH > _board.height) {
            y0 = _board.height + KSLPROBLEM_MARGIN - zoomedH;
        }
    }
    
    [self setZoomedAreaWithRect:
     CGRectMake(x0, y0, zoomedW, zoomedH)];
    
}

/**
 * 全体表示時の位置や点の間隔を予め計算しておく
 */
- (void)calculateOverallParameter
{
    CGFloat w;
    CGFloat h;
    if (_rotated) {
        w = self.frame.size.height;
        h = self.frame.size.width;
    } else {
        w = self.frame.size.width;
        h = self.frame.size.height;
    }
    
    CGFloat pitchH = w / (_board.width + 2 * KSLPROBLEM_MARGIN);
    CGFloat pitchV = h / (_board.height + 2 * KSLPROBLEM_MARGIN);
    if (pitchH > KSLPROBLEM_TOUCHABLE_PITCH && pitchV > KSLPROBLEM_TOUCHABLE_PITCH) {
        // 実際には常にズーム中として扱うため使用されない
        _apitch = KSLPROBLEM_TOUCHABLE_PITCH;
        if (_rotated) {
            _ax0 = (h - _apitch * _board.height) / 2;
            _ay0 = w - (w - _apitch * _board.width) / 2;
        } else {
            _ax0 = (w - _apitch * _board.width) / 2;
            _ay0 = (h - _apitch * _board.height) / 2;
        }
    } else if (pitchH < pitchV) {
        _apitch = pitchH;
        if (_rotated) {
            _ax0 = (h - _apitch * _board.height) / 2;
            _ay0 = w - _apitch * KSLPROBLEM_MARGIN;
        } else {
            _ax0 = _apitch * KSLPROBLEM_MARGIN;
            _ay0 = (h - _apitch * _board.height) / 2;
        }
    } else {
        _apitch = pitchV;
        if (_rotated) {
            _ax0 = _apitch * KSLPROBLEM_MARGIN;
            _ay0 = w - (w - _apitch * _board.width) / 2;
        } else {
            _ax0 = (w - _apitch * _board.width) / 2;
            _ay0 = _apitch * KSLPROBLEM_MARGIN;
        }
    }
}

/**
 * ズーム時の位置や点の間隔を予め計算しておく
 */
- (void)calculateZoomedParameter
{
    CGFloat w;
    CGFloat h;
    if (_rotated) {
        w = self.frame.size.height / _zpitch;
        h = self.frame.size.width / _zpitch;
    } else {
        w = self.frame.size.width / _zpitch;
        h = self.frame.size.height / _zpitch;
    }
    
    CGFloat zxmin;
    CGFloat zxmax;
    CGFloat zymin;
    CGFloat zymax;
    
    if (_board.width + 2 * KSLPROBLEM_MARGIN < w) {
        zxmin = zxmax = (w - _board.width) / 2;
        _fixH = YES;
    } else {
        zxmin = w - (_board.width + KSLPROBLEM_MARGIN);
        zxmax = KSLPROBLEM_MARGIN;
        _fixH = NO;
    }
    
    if (_board.height + 2 * KSLPROBLEM_MARGIN < h) {
        zymin = zymax = (h - _board.height) / 2;
        _fixV = YES;
    } else {
        zymin = h - (_board.height + KSLPROBLEM_MARGIN);
        zymax = KSLPROBLEM_MARGIN;
        _fixV = NO;
    }
    
    _zoomableArea = CGRectMake(-zxmax, -zymax, zxmax + w - zxmin, zymax + h - zymin);
}

/**
 * 拡大表示領域を設定する
 * @param rect 領域を指定する長方形（問題座標系）
 */
- (void)setZoomedAreaWithRect:(CGRect)rect
{
    CGRect zoomedArea = KLCGClumpRect(rect, _zoomableArea);
    _delegate.zoomedArea = zoomedArea;
    if (_rotated) {
        _zx0 = -zoomedArea.origin.y * _zpitch;
        _zy0 = self.frame.size.height + zoomedArea.origin.x * _zpitch;
    } else {
        _zx0 = -zoomedArea.origin.x * _zpitch;
        _zy0 = -zoomedArea.origin.y * _zpitch;
    }
}

/**
 * 拡大領域の表示座標系上での位置を得る
 * @return 拡大領域の表示座標系上での位置
 */
- (CGRect)zoomedAreaInView
{
    CGFloat x;
    CGFloat y;
    CGFloat w;
    CGFloat h;
    CGRect zoomedArea = _delegate.zoomedArea;
    if (_rotated) {
        x = _ax0 + zoomedArea.origin.y * _apitch;
        y = _ay0 - (zoomedArea.origin.x + zoomedArea.size.width) * _apitch;
        w = zoomedArea.size.height * _apitch;
        h = zoomedArea.size.width * _apitch;
    } else {
        x = _ax0 + zoomedArea.origin.x * _apitch;
        y = _ay0 + zoomedArea.origin.y * _apitch;
        w = zoomedArea.size.width * _apitch;
        h = zoomedArea.size.height * _apitch;
    }
    return CGRectMake(x, y, w, h);
}

/**
 * 拡大領域を移動する
 * @param translation 拡大領域を移動する量（表示座標系）
 */
- (void)panZoomedArea:(CGPoint)translation
{
    CGRect zoomedArea = _delegate.zoomedArea;
    if (_rotated) {
        [self setZoomedAreaWithRect:CGRectOffset(zoomedArea,
                                                 translation.y / _zpitch, -translation.x / _zpitch)];
    } else {
        [self setZoomedAreaWithRect:CGRectOffset(zoomedArea,
                                                 -translation.x / _zpitch, -translation.y / _zpitch)];
    }
}

#pragma mark - プライベートメソッド（検索）

/**
 * 指定の座標の近傍のノードを得る
 * @param point 座標
 * @return 指定の座標の近傍のノード
 */
- (KSLNode *)findNode:(CGPoint)point
{
    CGFloat xp;
    CGFloat yp;
    if (_rotated) {
        xp = -(point.y - _zy0) / _zpitch;
        yp = (point.x - _zx0) / _zpitch;
    } else {
        xp = (point.x - _zx0) / _zpitch;
        yp = (point.y - _zy0) / _zpitch;
    }
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

/**
 * 指定の座標の含まれるセルを得る
 * @param point 座標
 * @return 指定の座標の含まれるセル
 */
- (KSLCell *)findCell:(CGPoint)point
{
    CGFloat xp;
    CGFloat yp;
    if (_rotated) {
        xp = -(point.y - _zy0) / _zpitch;
        yp = (point.x - _zx0) / _zpitch;
    } else {
        xp = (point.x - _zx0) / _zpitch;
        yp = (point.y - _zy0) / _zpitch;
    }
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

/**
 * 指定の座標が中点の近傍の辺を得る
 * @param point 座標
 * @return 指定の座標が中点の近傍の辺
 */
- (KSLEdge *)findEdge:(CGPoint)point
{
    CGFloat xp;
    CGFloat yp;
    if (_rotated) {
        xp = -(point.y - _zy0) / _zpitch;
        yp = (point.x - _zx0) / _zpitch;
    } else {
        xp = (point.x - _zx0) / _zpitch;
        yp = (point.y - _zy0) / _zpitch;
    }
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

#pragma mark - プライベートメソッド（その他）

/**
 * 問題の正規の向きに対して画面が回転しているかどうかを調べる
 * @return 問題の正規の向きに対して画面が回転しているかどうか
 */
- (BOOL)checkRotation
{
    return (_board.width > _board.height && self.frame.size.width <= self.frame.size.height) ||
            (_board.width <= _board.height && self.frame.size.width > self.frame.size.height);
}

/**
 * 画面に表示中の軌跡をクリアする
 */
- (void)clearTrackes
{
    [_tracks removeAllObjects];
    [self setNeedsDisplay];
}

@end
