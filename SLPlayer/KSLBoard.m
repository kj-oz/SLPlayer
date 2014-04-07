//
//  KSLBoard.m
//  SLPlayer
//
//  Created by KO on 13/10/27.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import "KSLBoard.h"
#import "KSLProblem.h"

#pragma mark - KSLCell

@implementation KSLCell

- (id)initWithNumber:(NSInteger)aNumber
{
    self = [super init];
    if (self) {
        _number = aNumber;
    }
    return self;
}

- (NSString *)description
{
    KSLNode *node = [_topEdge nodeOfLH:0];
    return [NSString stringWithFormat:@"C%02ld%02ld", (long)node.x, (long)node.y];
}

- (KSLEdge *)oppsiteEdgeOfEdge:(KSLEdge *)edge
{
    if (edge == _topEdge) {
        return _bottomEdge;
    } else if (edge == _leftEdge) {
        return _rightEdge;
    } else if (edge == _bottomEdge) {
        return _topEdge;
    } else if (edge == _rightEdge) {
        return _leftEdge;
    }
    return nil;
}

- (void)changeNumber:(NSInteger)number
{
    _number = number;
}

@end


#pragma mark - KSLNode

@implementation KSLNode
{
    // 各方向のGateの状態
    KSLGateStatus _gateStatus[2];
}

- (id)initWithX:(NSInteger)aX andY:(NSInteger)aY
{
    self = [super init];
    if (self) {
        _x = aX;
        _y = aY;
        _oppositeNode = nil;
        _gateStatus[0] = KSLGateStatusUnset;
        _gateStatus[1] = KSLGateStatusUnset;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"N%02ld%02ld", (long)_x, (long)_y];
}

- (KSLEdge *)onEdgeConnectToEdge:(KSLEdge *)edge
{
    if (_upEdge.status == KSLEdgeStatusOn && _upEdge != edge) {
        return _upEdge;
    } else if (_leftEdge.status == KSLEdgeStatusOn && _leftEdge != edge) {
        return _leftEdge;
    } else if (_downEdge.status == KSLEdgeStatusOn && _downEdge != edge) {
        return _downEdge;
    } else if (_rightEdge.status == KSLEdgeStatusOn && _rightEdge != edge) {
        return _rightEdge;
    }
    return nil;
}

- (KSLGateStatus)gateStatusOfDir:(NSInteger)dir
{
    return _gateStatus[dir];
}

- (void)setGateStatusOfDir:(NSInteger)dir toStatus:(KSLGateStatus)status
{
    _gateStatus[dir] = status;
}

@end


#pragma mark - KSLEdge

@implementation KSLEdge
{
    // 左右のCell
    __unsafe_unretained KSLCell *_cell[2];
    
    // 前後のNode
    __unsafe_unretained KSLNode *_node[2];
    
    // 前後の延長上のEdge
    __unsafe_unretained KSLEdge *_straightEdge[2];
}

#pragma mark - KSLEdge 初期化

- (id)initWithHorizontal:(BOOL)isHorizontal
{
    return [self initWithStatus:KSLEdgeStatusUnset andHorizontal:isHorizontal];
}

- (id)initWithStatus:(KSLEdgeStatus)aStatus andHorizontal:(BOOL)isHorizontal
{
    self = [super init];
    if (self) {
        _status = aStatus;
        _horizontal = isHorizontal;
    }
    return self;
}

#pragma mark - KSLEdge プロパティ

- (NSString *)description
{
    char dir = _horizontal ? 'H' : 'V';
    if (!_node[0] || !_node[1]) {
        return [NSString stringWithFormat:@"%cDUMM", dir];
    }
    return [NSString stringWithFormat:@"%c%02ld%02ld", dir, (long)_node[0].x, (long)_node[0].y];
}

- (void)setStatus:(KSLEdgeStatus)aStatus
{
    if (_status == aStatus) return;
    
    if (_status == KSLEdgeStatusOn) {
        _node[0].onCount--;
        _node[1].onCount--;
        _cell[0].onCount--;
        _cell[1].onCount--;
    } else if (_status == KSLEdgeStatusOff) {
        _node[0].offCount--;
        _node[1].offCount--;
        _cell[0].offCount--;
        _cell[1].offCount--;
    }

    if (aStatus == KSLEdgeStatusOn) {
        _node[0].onCount++;
        _node[1].onCount++;
        _cell[0].onCount++;
        _cell[1].onCount++;
    } else if (aStatus == KSLEdgeStatusOff) {
        _node[0].offCount++;
        _node[1].offCount++;
        _cell[0].offCount++;
        _cell[1].offCount++;
    }
    _status = aStatus;
}

#pragma mark - KSLEdge 周辺要素

- (KSLNode *)anotherNodeOfNode:(KSLNode *)aNode
{
    return (_node[0] == aNode) ? _node[1] : _node[0];
}

- (KSLCell *)cellOfDir:(NSInteger)dir
{
    return _cell[dir];
}

- (void)setCellOfDir:(NSInteger)dir toCell:(KSLCell *)aCell
{
    _cell[dir] = aCell;
}

- (KSLNode *)nodeOfLH:(NSInteger)lh
{
    return _node[lh];
}

- (void)setNodeOfLH:(NSInteger)lh toNode:(KSLNode *)aNode
{
    _node[lh] = aNode;
}

- (KSLEdge *)straightEdgeOfLH:(NSInteger)lh
{
    return _straightEdge[lh];
}

- (void)setStraightEdgeOfLH:(NSInteger)lh toEdge:(KSLEdge *)edge
{
    _straightEdge[lh] = edge;
}

@end


#pragma mark - KSLBoard

@implementation KSLBoard
{
    KSLEdge *_dummyHEdge;
    KSLEdge *_dummyVEdge;
    KSLCell *_dummyCell;
}

#pragma mark - 初期化

- (id)initWithProblem:(KSLProblem *)problem
{
    self = [super init];
    if (self) {
        _width = problem.width;
        _height = problem.height;
        
        _cells = [NSMutableArray arrayWithCapacity:(_width * _height)];
        _nodes = [NSMutableArray arrayWithCapacity:((_width + 1) * (_height * 1))];
        _hEdges = [NSMutableArray arrayWithCapacity:(_width * (_height * 1))];
        _vEdges = [NSMutableArray arrayWithCapacity:((_width + 1) * _height)];
        
        [self _createElemntsWithProblem:problem];
        [self _connectElements];
    }
    return self;
}

#pragma mark - 要素の取得

- (KSLCell *)cellAtX:(NSInteger)x andY:(NSInteger)y
{
    return _cells[y * _width + x];
}

- (KSLNode *)nodeAtX:(NSInteger)x andY:(NSInteger)y
{
    return _nodes[y * (_width + 1) + x];
}

- (KSLEdge *)hEdgeAtX:(NSInteger)x andY:(NSInteger)y
{
    return _hEdges[y * _width + x];
}

- (KSLEdge *)vEdgeAtX:(NSInteger)x andY:(NSInteger)y
{
    return _vEdges[y * (_width + 1) + x];
}

#pragma mark - 要素の検索

- (KSLNode *)findOpenNode
{
    for (KSLNode *node in _nodes) {
        if (node.onCount == 1) {
            return node;
        }
    }
    return nil;
}

- (KSLCell *)findCellForBranch
{
    for (NSInteger n = 3; n > 0; n--) {
        for (KSLCell *cell in _cells) {
            if (cell.number == n && cell.onCount == n - 1 && cell.offCount + cell.onCount < 4) {
                return cell;
            }
        }
    }
    return nil;
}

- (KSLCell *)findOpenCell
{
    for (KSLCell *cell in _cells) {
        if (cell.number > 0 && cell.number != cell.onCount) {
            return cell;
        }
    }
    return nil;
}

- (KSLEdge *)findOnEdge
{
    for (KSLEdge *edge in _hEdges) {
        if (edge.status == KSLEdgeStatusOn) {
            return edge;
        }
    }
    for (KSLEdge *edge in _vEdges) {
        if (edge.status == KSLEdgeStatusOn) {
            return edge;
        }
    }
    return nil;
}

- (KSLCell *)get3Across2FromCell:(KSLCell *)cell withDx:(NSInteger)dx dy:(NSInteger)dy
{
    KSLNode *node = [cell.topEdge nodeOfLH:0];
    NSInteger x = node.x + dx;
    NSInteger y = node.y + dy;
    while (0 <= x && x < _width && 0 <= y && y < _height) {
        cell = [self cellAtX:x andY:y];
        if (cell.number == 2) {
            x += dx;
            y += dy;
            continue;
        }
        return (cell.number == 3 ? cell : nil);
    }
    return nil;
}

- (KSLEdge *)getJointEdgeOfNodes:(KSLNode *)node1 and:(KSLNode *)node2
{
    NSInteger x1 = node1.x, y1 = node1.y;
    NSInteger x2 = node2.x, y2 = node2.y;
    if (x1 == x2 && ABS(y1 - y2) == 1) {
        return [self vEdgeAtX:x1 andY:MIN(y1, y2)];
    } else if (y1 == y2 && ABS(x1 - x2) == 1) {
        return [self hEdgeAtX:MIN(x1, x2) andY:y1];
    }
    return nil;
}

- (KSLNode *)getLoopEndWithNode:(KSLNode *)root andEdge:(KSLEdge *)edge
{
    KSLNode *node = [edge anotherNodeOfNode:root];
    
    while (node && node.onCount == 2) {
        edge = [node onEdgeConnectToEdge:edge];
        node = [edge anotherNodeOfNode:node];
        
        if (node == root) {
            return nil;
        }
    }
    return node;
}

- (KSLEdge *)findEdgeWithId:(NSString *)identifier
{
    char dir = [identifier characterAtIndex:0];
    NSInteger x = [[identifier substringWithRange:NSMakeRange(1, 2)] intValue];
    NSInteger y = [[identifier substringWithRange:NSMakeRange(3, 2)] intValue];
    return dir == 'H' ? [self hEdgeAtX:x andY:y] : [self vEdgeAtX:x andY:y];
}

#pragma mark - その他の情報の取得

- (NSInteger)nodeIndex:(KSLNode *)node
{
    if (node) {
        return node.y * (_width + 1) + node.x;
    } else {
        return -1;
    }
}

- (BOOL)isLoopFinishedOfEdge:(KSLEdge *)edge
{
    if ([self findOpenCell] != nil) {
        return NO;
    }
    
    KSLNode *root = [edge nodeOfLH:0];
    KSLNode *node = [edge nodeOfLH:1];
    NSInteger conCount = 1;
    while (node != root) {
        edge = [node onEdgeConnectToEdge:edge];
        if (!edge) {
            return NO;
        }
        conCount++;
        
        node = [edge anotherNodeOfNode:node];
    }
    
    return conCount == [self countOnEdge];
}

- (NSArray *)route
{
    KSLEdge *edge = [self findOnEdge];
    
    KSLNode *root = [edge nodeOfLH:0];
    KSLNode *node = [edge nodeOfLH:1];
    NSMutableArray *route = [NSMutableArray array];
    [route addObject:edge];
    while (node != root) {
        edge = [node onEdgeConnectToEdge:edge];
        [route addObject:edge];
        
        node = [edge anotherNodeOfNode:node];
    }
    return route;
}

- (NSInteger)countOnEdge
{
    NSInteger onCount = 0;
    for (KSLEdge *edge in _hEdges) {
        if (edge.status == KSLEdgeStatusOn) {
            onCount++;
        }
    }
    for (KSLEdge *edge in _vEdges) {
        if (edge.status == KSLEdgeStatusOn) {
            onCount++;
        }
    }
    return onCount;
}

#pragma mark - Play時のみ

- (void)fixStatus
{
    for (KSLEdge *edge in _hEdges) {
        if (edge.status != KSLEdgeStatusUnset) {
            edge.fixed = YES;
        }
    }
    for (KSLEdge *edge in _vEdges) {
        if (edge.status != KSLEdgeStatusUnset) {
            edge.fixed = YES;
        }
    }
}

- (void)erase
{
    for (KSLEdge *edge in _hEdges) {
        if (edge.status != KSLEdgeStatusUnset && !edge.fixed) {
            edge.status = KSLEdgeStatusUnset;
        }
    }
    for (KSLEdge *edge in _vEdges) {
        if (edge.status != KSLEdgeStatusUnset && !edge.fixed) {
            edge.status = KSLEdgeStatusUnset;
        }
    }
}

- (void)clear
{
    for (KSLEdge *edge in _hEdges) {
        edge.status = KSLEdgeStatusUnset;
        edge.fixed = NO;
    }
    for (KSLEdge *edge in _vEdges) {
        edge.status = KSLEdgeStatusUnset;
        edge.fixed = NO;
    }
}

#pragma mark - 出力

- (void)dump
{
    for (NSInteger y = 0; y < _height; y++) {
        for (NSInteger x = 0; x < _width; x++) {
            KSLEdge *edge = [self hEdgeAtX:x andY:y];
            printf("+ %c ", [self edgeStatusCharH:edge]);
        }
        printf("+\n");
        
        for (NSInteger x = 0; x < _width; x++) {
            KSLEdge *edge = [self vEdgeAtX:x andY:y];
            printf("%c ", [self edgeStatusCharV:edge]);
            KSLCell *cell = [self cellAtX:x andY:y];
            if (cell.number >= 0) {
                printf("%ld ", (long)cell.number);
            } else {
                printf("  ");
            }
        }
        KSLEdge *edge = [self vEdgeAtX:_width andY:y];
        printf("%c\n", [self edgeStatusCharV:edge]);
    }
    for (NSInteger x = 0; x < _width; x++) {
        KSLEdge *edge = [self hEdgeAtX:x andY:_height];
        printf("+ %c ", [self edgeStatusCharH:edge]);
    }
    printf("+\n");
}

- (UIImage *)createImageWithWidth:(NSInteger)imageWidth andHeight:(NSInteger)imageHeight
{
    UIGraphicsBeginImageContext(CGSizeMake(imageWidth, imageHeight));
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, imageWidth, imageHeight));
    
    CGFloat pitchH = imageWidth / (_width + 2);
    CGFloat pitchV = imageHeight / (_height + 2);
    CGFloat pitch = MIN(pitchH, pitchV);

    CGFloat x0 = (imageWidth - pitch * _width) / 2;
    CGFloat y0 = (imageHeight - pitch * _height) / 2;
    
    [self drawImageWithContext:context origin:CGPointMake(x0, y0) pitch:pitch
                 erasableColor:[UIColor blackColor].CGColor];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)drawImageWithContext:(CGContextRef)context
                      origin:(CGPoint)origin pitch:(CGFloat)pitch
               erasableColor:(CGColorRef)erasableColor
{
    CGFloat charH = 0.8 * pitch;
    CGFloat pointR = 0.03 * pitch;
    CGFloat lineW = 0.06 * pitch;
    CGFloat crossLineW = 0.04 * pitch;
    CGFloat crossR = 0.08 * pitch;
    
    CGColorRef fixedColor = [UIColor blackColor].CGColor;
    
    NSInteger x0 = origin.x;
    NSInteger y0 = origin.y;
    
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(context, crossLineW);
    CGContextSetShouldAntialias(context, NO);
    
    for (NSInteger v = 0; v <= _height; v++) {
        CGFloat y = y0 + v * pitch;
        for (NSInteger u = 0; u <= _width; u++) {
            CGFloat x = x0 + u * pitch;
            CGRect rect = CGRectMake(x-pointR, y-pointR, pointR * 2, pointR * 2);
            CGContextFillRect(context, rect);
        }
    }
    
    NSArray *chars = @[@"0", @"1", @"2", @"3"];
    UIFont *font = [UIFont systemFontOfSize:charH];
    CGContextSetShouldAntialias(context, YES);
    CGSize size = [@"0" sizeWithFont:font];
    CGFloat nx = (pitch - size.width) * 0.5 + 0.5;
    CGFloat ny = (pitch - size.height) * 0.5;
    for (NSInteger v = 0; v < _height; v++) {
        CGFloat y = y0 + v * pitch + ny;
        for (NSInteger u = 0; u < _width; u++) {
            CGFloat x = x0 + u * pitch + nx;
            NSInteger number = [self cellAtX:u andY:v].number;
            if (number >= 0) {
                [chars[number] drawAtPoint:CGPointMake(x, y) withFont:font];
            }
        }
    }
    
    for (NSInteger v = 0; v <= _height; v++) {
        CGFloat y = y0 + v * pitch;
        for (NSInteger u = 0; u < _width; u++) {
            CGFloat x = x0 + u * pitch;
            KSLEdge *edge = [self hEdgeAtX:u andY:v];
            CGContextSetFillColorWithColor(context, edge.fixed ? fixedColor : erasableColor);
            CGContextSetStrokeColorWithColor(context, edge.fixed ? fixedColor : erasableColor);
            KSLEdgeStatus status = edge.status;
            if (status == KSLEdgeStatusOn) {
                CGRect rect = CGRectMake(x+pointR, y-lineW*0.5, pitch-2*pointR, lineW);
                CGContextFillRect(context, rect);
            } else if (status == KSLEdgeStatusOff) {
                [self drawCrossWithContext:context cx:x+0.5*pitch cy:y halfSize:crossR];
            }
        }
    }
    
    for (NSInteger v = 0; v < _height; v++) {
        CGFloat y = y0 + v * pitch;
        for (NSInteger u = 0; u <= _width; u++) {
            CGFloat x = x0 + u * pitch;
            KSLEdge *edge = [self vEdgeAtX:u andY:v];
            CGContextSetFillColorWithColor(context, edge.fixed ? fixedColor : erasableColor);
            CGContextSetStrokeColorWithColor(context, edge.fixed ? fixedColor : erasableColor);
            KSLEdgeStatus status = edge.status;
            if (status == KSLEdgeStatusOn) {
                CGRect rect = CGRectMake(x-lineW*0.5, y+pointR, lineW, pitch-2*pointR);
                CGContextFillRect(context, rect);
            } else if (status == KSLEdgeStatusOff) {
                [self drawCrossWithContext:context cx:x cy:y+0.5*pitch halfSize:crossR];
            }
        }
    }
    
}

#pragma mark - プライベートメソッド

/**
 * 盤面を構成する各要素を構築する.
 * @param problem 問題
 */
- (void)_createElemntsWithProblem:(KSLProblem *)problem
{
    _dummyHEdge = [[KSLEdge alloc] initWithStatus:KSLEdgeStatusOff andHorizontal:YES];
    _dummyVEdge = [[KSLEdge alloc] initWithStatus:KSLEdgeStatusOff andHorizontal:NO];
    _dummyCell = [[KSLCell alloc] initWithNumber:-1];
    
    for (NSInteger y = 0; y < _height; y++) {
        for (NSInteger x = 0; x < _width; x++) {
            [_cells addObject:[[KSLCell alloc] initWithNumber:[problem valueOfX:x andY:y]]];
        }
    }
    
    for (NSInteger y = 0; y <= _height; y++) {
        for (NSInteger x = 0; x <= _width; x++) {
            [_nodes addObject:[[KSLNode alloc] initWithX:x andY:y]];
        }
    }
    
    NSInteger n = _width * (_height + 1);
    for (NSInteger i = 0; i < n; i++) {
        KSLEdge *edge = [[KSLEdge alloc] initWithHorizontal:YES];
        [_hEdges addObject:edge];
    }
    n = (_width  + 1) * _height;
    for (NSInteger i = 0; i < n; i++) {
        KSLEdge *edge = [[KSLEdge alloc] initWithHorizontal:NO];
        [_vEdges addObject:edge];
    }
}

/**
 * 盤面の各要素を接続する.
 */
- (void)_connectElements
{
    [_dummyHEdge setCellOfDir:0 toCell:_dummyCell];
    [_dummyHEdge setCellOfDir:1 toCell:_dummyCell];
    [_dummyVEdge setCellOfDir:0 toCell:_dummyCell];
    [_dummyVEdge setCellOfDir:1 toCell:_dummyCell];
    
    for (NSInteger y = 0; y < _height; y++) {
        for (NSInteger x = 0; x < _width; x++) {
            KSLCell *cell = _cells[y * _width + x];
            KSLEdge *topEdge = _hEdges[y * _width + x];
            KSLEdge *bottomEdge = _hEdges[(y + 1) * _width + x];
            KSLEdge *leftEdge = _vEdges[y * (_width + 1) + x];
            KSLEdge *rightEdge = _vEdges[y * (_width + 1) + x + 1];
            
            cell.topEdge = topEdge;
            [topEdge setCellOfDir:1 toCell:cell];
            
            cell.bottomEdge = bottomEdge;
            [bottomEdge setCellOfDir:0 toCell:cell];
            
            cell.leftEdge = leftEdge;
            [leftEdge setCellOfDir:1 toCell:cell];
            
            cell.rightEdge = rightEdge;
            [rightEdge setCellOfDir:0 toCell:cell];
            
            if (y == 0) {
                [topEdge setCellOfDir:0 toCell:_dummyCell];
            }
            if (y == _height - 1) {
                [bottomEdge setCellOfDir:1 toCell:_dummyCell];
            }
            if (x == 0) {
                [leftEdge setCellOfDir:0 toCell:_dummyCell];
            }
            if (x == _width - 1) {
                [rightEdge setCellOfDir:1 toCell:_dummyCell];
            }
        }
    }
    
    for (NSInteger y = 0; y <= _height; y++) {
        for (NSInteger x = 0; x <= _width; x++) {
            KSLNode *node = _nodes[y * (_width + 1) + x];
            
            if (x == 0) {
                node.leftEdge = _dummyHEdge;
                node.offCount++;
            } else {
                KSLEdge *edge = _hEdges[y * _width + x - 1];
                node.leftEdge = edge;
                [edge setNodeOfLH:1 toNode:node];
            }
            
            if (x == _width) {
                node.rightEdge = _dummyHEdge;
                node.offCount++;
            } else {
                KSLEdge *edge = _hEdges[y * _width + x];
                node.rightEdge = edge;
                [edge setNodeOfLH:0 toNode:node];
            }
            
            if (y == 0) {
                node.upEdge = _dummyVEdge;
                node.offCount++;
            } else {
                KSLEdge *edge = _vEdges[(y - 1) * (_width + 1) + x];
                node.upEdge = edge;
                [edge setNodeOfLH:1 toNode:node];
            }
            
            if (y == _height) {
                node.downEdge = _dummyVEdge;
                node.offCount++;
            } else {
                KSLEdge *edge = _vEdges[y * (_width + 1) + x];
                node.downEdge = edge;
                [edge setNodeOfLH:0 toNode:node];
            }
        }
    }
    
    for (NSInteger y = 0; y <= _height; y++) {
        for (NSInteger x = 0; x < _width; x++) {
            KSLEdge *edge = _hEdges[y * _width + x];
            [edge setStraightEdgeOfLH:0 toEdge:[edge nodeOfLH:0].leftEdge];
            [edge setStraightEdgeOfLH:1 toEdge:[edge nodeOfLH:1].rightEdge];
        }
    }
    
    for (NSInteger y = 0; y < _height; y++) {
        for (NSInteger x = 0; x <= _width; x++) {
            KSLEdge *edge = _vEdges[y * (_width + 1) + x];
            [edge setStraightEdgeOfLH:0 toEdge:[edge nodeOfLH:0].upEdge];
            [edge setStraightEdgeOfLH:1 toEdge:[edge nodeOfLH:1].downEdge];
        }
    }
}

/**
 * 水平方向のEdgeを表す状態に応じた文字を得る.
 * @param edge Edge
 * @return 状態に応じた文字
 */
- (char)edgeStatusCharH:(KSLEdge *)edge
{
    switch (edge.status) {
        case KSLEdgeStatusUnset: return ' ';
        case KSLEdgeStatusOn: return '-';
        case KSLEdgeStatusOff: return 'X';
    }
}

/**
 * 垂直方向のEdgeを表す状態に応じた文字を得る.
 * @param edge Edge
 * @return 状態に応じた文字
 */
- (char)edgeStatusCharV:(KSLEdge *)edge
{
    switch (edge.status) {
        case KSLEdgeStatusUnset: return ' ';
        case KSLEdgeStatusOn: return '|';
        case KSLEdgeStatusOff: return 'X';
    }
}

/**
 * 与えられたコンテキストの指定の位置に×印を描画する.
 * @param contex 描画コンテキスト
 * @param cx ×の中心位置のX座標
 * @param cy ×の中心位置のY座標
 * @param r xの幅の1/2
 */
- (void)drawCrossWithContext:(CGContextRef)context cx:(CGFloat)cx cy:(CGFloat)cy halfSize:(CGFloat)r
{
    CGFloat x1 = cx - r;
    CGFloat y1 = cy - r;
    CGFloat x2 = cx + r;
    CGFloat y2 = cy + r;
    CGPoint points[2];
    points[0] = CGPointMake(x1, y1);
    points[1] = CGPointMake(x2, y2);
    CGContextStrokeLineSegments(context, points, 2);
    points[0] = CGPointMake(x1, y2);
    points[1] = CGPointMake(x2, y1);
    CGContextStrokeLineSegments(context, points, 2);
}

@end
