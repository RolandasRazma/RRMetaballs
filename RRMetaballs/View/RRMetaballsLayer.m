//
//  RRMetaballsLayer.m
//  RRMetaballs
//
//  Copyright (c) 2014 Rolandas Razma <rolandas@razma.lt>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "RRMetaballsLayer.h"
#import <UIKit/UIKit.h>


#define pow2( __NUMBER__ ) ( (__NUMBER__) *(__NUMBER__) )


#define RRMarchingSquareEdge0 0
#define RRMarchingSquareEdgeW 1
#define RRMarchingSquareEdgeS 2
#define RRMarchingSquareEdgeN 3
#define RRMarchingSquareEdgeE 4


struct RRMarchingSquare {
    int a;
    int b;
    int c;
    int d;
}; typedef struct RRMarchingSquare RRMarchingSquare;


struct RRBall {
    CGPoint center;
    float   radius;
    float   radiuspow2;
    
    CGFloat colorR;
    CGFloat colorG;
    CGFloat colorB;
    CGFloat colorA;
}; typedef struct RRBall RRBall;


static inline RRBall RRBallMake(CGPoint center, const float radius, CGColorRef color) {
    RRBall ball;
    ball.center = center;
    ball.radius = radius;
    ball.radiuspow2 = pow2(radius);
    
    const CGFloat *components = CGColorGetComponents(color);
    if( CGColorGetNumberOfComponents(color) == 2 ) {
        ball.colorR = ball.colorG = ball.colorB = components[0];
        ball.colorA = components[1];
    } else if ( CGColorGetNumberOfComponents(color) == 4 ) {
        ball.colorR = components[0];
        ball.colorG = components[1];
        ball.colorB = components[2];
        ball.colorA = components[3];
    }
    
    return ball;
}


/**
 * Feald streangth
 */
static inline float metaball(const CGFloat originX, const CGFloat originY, const RRBall *balls, const int ballsLength) {

    float sum = 0.0f;
    for ( int i = 0; i < ballsLength; i++ ) {
        RRBall ball = balls[i];
        
        CGFloat dx = originX -ball.center.x;
        CGFloat dy = originY -ball.center.y;
        
        CGFloat d2 = pow2(dx) +pow2(dy);
        
        if( d2 != 0.0f ){
            sum += ball.radiuspow2 /d2;
        }else{
            sum += 100000.0f;
        }
    }
    
    return sum;
}


/**
 * Linear interpolation
 */
static inline float lerp(const float x0, const float x1, const float y0, const float y1, const float t) {
    if ( x0 == x1 ) {
        // return null
    }
    return y0 +(y1 -y0) *(t -x0) /(x1 -x0);
}


static inline void CGContextAddLineFromPointToPoint(const CGContextRef contextRef, const CGPoint startPoint, const CGPoint endPoint, CGPoint *lastEndPoint) {
    
    if( CGPointEqualToPoint(endPoint, *lastEndPoint) ){
        CGContextAddLineToPoint(contextRef, startPoint.x, startPoint.y);
        *lastEndPoint = startPoint;
    }else if( CGPointEqualToPoint(startPoint, *lastEndPoint) ){
        CGContextAddLineToPoint(contextRef, endPoint.x, endPoint.y);
        *lastEndPoint = endPoint;
    }else{
        CGContextMoveToPoint(contextRef, startPoint.x, startPoint.y);
        CGContextAddLineToPoint(contextRef, endPoint.x, endPoint.y);
        *lastEndPoint = endPoint;
    }
    
}


@implementation RRMetaballsLayer {
    RRMarchingSquare _cellTypeToMarchingSquare[16];
    
    float   _threshold;
    float   _colorThreshold;
    
    RRBall *_balls;
    int     _ballsMax;
    int     _ballsLength;

    int     *_cellTypes;
    float   *_samples;
    int     _samplesRows;
    int     _samplesCols;
    
    BOOL    _needsRecalculate;
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    
    if( _balls ){
        free(_balls);
    }
    
    if( _samples ){
        free(_samples);
    }
    
    if( _cellTypes ){
        free(_cellTypes);
    }
    
}


- (void)setValue:(id)value forKey:(NSString *)key {
    if( [key isEqualToString:@"cellSize"] || [key isEqualToString:@"centers"] || [key isEqualToString:@"radiuses"] || [key isEqualToString:@"colors"] ){
        _needsRecalculate = YES;
    }
    
    [super setValue:value forKey:key];
}


- (void)willChangeValueForKey:(NSString *)key {
    if( [key isEqualToString:@"cellSize"] || [key isEqualToString:@"centers"] || [key isEqualToString:@"radiuses"] || [key isEqualToString:@"colors"] ){
        _needsRecalculate = YES;
    }
    
    [super willChangeValueForKey:key];
}


#pragma mark -
#pragma mark CALayer


+ (BOOL)needsDisplayForKey:(NSString *)key {
    if( [key isEqualToString:@"cellSize"] || [key isEqualToString:@"centers"] || [key isEqualToString:@"radiuses"] || [key isEqualToString:@"colors"] ){
        return YES;
    }
    
    return [super needsDisplayForKey:key];
}


- (instancetype)init {
    if( (self = [super init]) ){
        [self setCellSize: 5.0f];

        [self setup];
        [self setNeedsDisplay];
    }
    return self;
}


- (instancetype)initWithLayer:(id)layer {
    if( (self = [super initWithLayer:layer]) ){
        [self setup];
        [self setNeedsDisplay];
    }
    return self;
}


- (void)drawInContext:(CGContextRef)contextRef {

    if( _needsRecalculate ){
        [self recalculate];
    }
    
    [self drawContoursInContext:contextRef];
    
}


#pragma mark -
#pragma mark RRMetaballsLayer


#define INDEX(__ROW__, __COL__) ((__ROW__) +(__COL__) *_samplesRows)


- (void)setup {
    _threshold          = 1.0f;
    _colorThreshold     = 0.0001f;
    
    _ballsMax           = 10;
    _balls              = malloc(_ballsMax *sizeof(*_balls));
    _ballsLength        = 0;

    _needsRecalculate   = YES;

    /**
     * Maps from 0-15 cell classification to compass points indicating a sequence of
     * corners to visit to form a polygon based on the pmapping described on
     * http://en.wikipedia.org/wiki/Marching_squares
     */
    _cellTypeToMarchingSquare[0]  = (RRMarchingSquare){RRMarchingSquareEdge0, RRMarchingSquareEdge0, RRMarchingSquareEdge0, RRMarchingSquareEdge0};
    _cellTypeToMarchingSquare[1]  = (RRMarchingSquare){RRMarchingSquareEdgeW, RRMarchingSquareEdgeS, RRMarchingSquareEdge0, RRMarchingSquareEdge0};
    _cellTypeToMarchingSquare[2]  = (RRMarchingSquare){RRMarchingSquareEdgeE, RRMarchingSquareEdgeS, RRMarchingSquareEdge0, RRMarchingSquareEdge0};
    _cellTypeToMarchingSquare[3]  = (RRMarchingSquare){RRMarchingSquareEdgeW, RRMarchingSquareEdgeE, RRMarchingSquareEdge0, RRMarchingSquareEdge0};
    _cellTypeToMarchingSquare[4]  = (RRMarchingSquare){RRMarchingSquareEdgeN, RRMarchingSquareEdgeE, RRMarchingSquareEdge0, RRMarchingSquareEdge0};
    _cellTypeToMarchingSquare[5]  = (RRMarchingSquare){RRMarchingSquareEdgeN, RRMarchingSquareEdgeW, RRMarchingSquareEdgeS, RRMarchingSquareEdgeE};
    _cellTypeToMarchingSquare[6]  = (RRMarchingSquare){RRMarchingSquareEdgeN, RRMarchingSquareEdgeS, RRMarchingSquareEdge0, RRMarchingSquareEdge0};
    _cellTypeToMarchingSquare[7]  = (RRMarchingSquare){RRMarchingSquareEdgeN, RRMarchingSquareEdgeW, RRMarchingSquareEdge0, RRMarchingSquareEdge0};
    _cellTypeToMarchingSquare[8]  = (RRMarchingSquare){RRMarchingSquareEdgeN, RRMarchingSquareEdgeW, RRMarchingSquareEdge0, RRMarchingSquareEdge0};
    _cellTypeToMarchingSquare[9]  = (RRMarchingSquare){RRMarchingSquareEdgeN, RRMarchingSquareEdgeS, RRMarchingSquareEdge0, RRMarchingSquareEdge0};
    _cellTypeToMarchingSquare[10] = (RRMarchingSquare){RRMarchingSquareEdgeN, RRMarchingSquareEdgeE, RRMarchingSquareEdgeS, RRMarchingSquareEdgeW};
    _cellTypeToMarchingSquare[11] = (RRMarchingSquare){RRMarchingSquareEdgeN, RRMarchingSquareEdgeE, RRMarchingSquareEdge0, RRMarchingSquareEdge0};
    _cellTypeToMarchingSquare[12] = (RRMarchingSquare){RRMarchingSquareEdgeE, RRMarchingSquareEdgeW, RRMarchingSquareEdge0, RRMarchingSquareEdge0};
    _cellTypeToMarchingSquare[13] = (RRMarchingSquare){RRMarchingSquareEdgeE, RRMarchingSquareEdgeS, RRMarchingSquareEdge0, RRMarchingSquareEdge0};
    _cellTypeToMarchingSquare[14] = (RRMarchingSquare){RRMarchingSquareEdgeS, RRMarchingSquareEdgeW, RRMarchingSquareEdge0, RRMarchingSquareEdge0};
    _cellTypeToMarchingSquare[15] = (RRMarchingSquare){RRMarchingSquareEdge0, RRMarchingSquareEdge0, RRMarchingSquareEdge0, RRMarchingSquareEdge0};
}


- (void)recalculate {

    _ballsLength = 0;
    [self.centers enumerateObjectsUsingBlock: ^(NSValue *center, NSUInteger index, BOOL *stop) {
        if( _ballsLength == _ballsMax ){
            _ballsMax += 10;
            
            RRBall *ballsNew = realloc(_balls, _ballsMax *sizeof(*_balls));
            if ( ballsNew != NULL ) {
                _balls = ballsNew;
            } else {
                free(_balls);
                printf("Error allocating memory!\n");
            }
        }
        
        _balls[_ballsLength++] = RRBallMake(center.CGPointValue, [self.radiuses[index] floatValue], (__bridge CGColorRef)self.colors[index]);
    }];
    
    
    int rows = (int)ceil(self.bounds.size.height /self.cellSize) +1;
    int cols = (int)ceil(self.bounds.size.width  /self.cellSize) +1;
    
    
    /**
     * Check for size
     */
    if( rows != _samplesRows || cols != _samplesCols ){
        _samplesRows = rows;
        _samplesCols = cols;
        
        if( _samples ){
            free(_samples);
        }
        _samples = calloc(_samplesRows *_samplesCols, sizeof(*_samples));
        
        if( _cellTypes ){
            free(_cellTypes);
        }
        
        _cellTypes = calloc(_samplesRows *_samplesCols, sizeof(*_cellTypes));
    }

    
    /**
     * Sample an f(x, y) in a 2D grid.
     */
    for ( int row = 0; row < _samplesRows; row++ ) {
        float y = row *self.cellSize;
        
        for ( int col = 0; col < _samplesCols; col++ ) {
            float x = col *self.cellSize;
            
            _samples[INDEX(row, col)] = metaball(x, y, _balls, _ballsLength);
        }
    }
    
    
    /**
     * Given a nxm grid of booleans, produce an (n-1)x(m-1) grid of square classifications
     * following the marching squares algorithm here:
     * http://en.wikipedia.org/wiki/Marching_squares
     * The input grid used as the values of the corners.
     *
     * The output grid is a 2D array of values 0-15
     */
    for ( int row = 0; row < _samplesRows -1; row++ ) {
        for ( int col = 0; col < _samplesCols -1; col++ ) {
            int NW = (_samples[INDEX(row   , col   )] > _threshold);
            int NE = (_samples[INDEX(row   , col +1)] > _threshold);
            int SW = (_samples[INDEX(row +1, col   )] > _threshold);
            int SE = (_samples[INDEX(row +1, col +1)] > _threshold);
            
            _cellTypes[INDEX(row, col)] = (SW << 0) +(SE << 1) +(NE << 2) +(NW << 3);
        }
    }
    
    
    // Mark as recalculated
    _needsRecalculate = NO;

}


- (void)drawContoursInContext:(CGContextRef)contextRef {

    CGPoint lastEndPoint;

    for ( int row = 0; row < _samplesRows; row++ ) {
        for ( int col = 0; col < _samplesCols; col++ ) {
            int cellType = _cellTypes[INDEX(row, col)];
            
            // skip unconnected.
            if( cellType == 0 || cellType == 15 ) {
                continue;
            }
            
            RRMarchingSquare polyCompassCorners = _cellTypeToMarchingSquare[cellType];
            
            // The samples at the 4 corners of the current cell
            float NW = _samples[INDEX(row   , col   )];
            float NE = _samples[INDEX(row   , col +1)];
            float SW = _samples[INDEX(row +1, col   )];
            float SE = _samples[INDEX(row +1, col +1)];
            
            // The offset from top or left that the line intersection should be.
            float offsetN = (cellType & 4) == (cellType & 8) ? 0.5f : lerp(NW, NE, 0.0f, 1.0f, _threshold);
            float offsetE = (cellType & 2) == (cellType & 4) ? 0.5f : lerp(NE, SE, 0.0f, 1.0f, _threshold);
            float offsetS = (cellType & 1) == (cellType & 2) ? 0.5f : lerp(SW, SE, 0.0f, 1.0f, _threshold);
            float offsetW = (cellType & 1) == (cellType & 8) ? 0.5f : lerp(NW, SW, 0.0f, 1.0f, _threshold);
            
            CGPoint compassCoords[5];
            compassCoords[RRMarchingSquareEdgeN] = CGPointMake((col +offsetN)   *self.cellSize, row             *self.cellSize);
            compassCoords[RRMarchingSquareEdgeW] = CGPointMake(col              *self.cellSize, (row +offsetW)  *self.cellSize);
            compassCoords[RRMarchingSquareEdgeE] = CGPointMake((col +1.0f)      *self.cellSize, (row +offsetE)  *self.cellSize);
            compassCoords[RRMarchingSquareEdgeS] = CGPointMake((col +offsetS)   *self.cellSize, (row +1.0f)     *self.cellSize);

            // 2 corners
            NSAssert2(polyCompassCorners.a, @"Invalid corners: %i and %i", polyCompassCorners.a, polyCompassCorners.b);
            CGContextAddLineFromPointToPoint(contextRef, compassCoords[polyCompassCorners.a], compassCoords[polyCompassCorners.b], &lastEndPoint);
            
            // 4 corners
            if ( polyCompassCorners.c || polyCompassCorners.d ) {
                CGContextAddLineFromPointToPoint(contextRef, compassCoords[polyCompassCorners.c], compassCoords[polyCompassCorners.d], &lastEndPoint);
            }
        }
    }
    
    CGContextSetStrokeColorWithColor(contextRef, [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f].CGColor);
    CGContextSetLineWidth(contextRef, 1.0f /self.contentsScale);
    CGContextStrokePath(contextRef);

}


#pragma mark -
#pragma mark @dynamic


@dynamic cellSize, colors, centers, radiuses;
@end
