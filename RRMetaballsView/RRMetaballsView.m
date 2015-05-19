//
//  RRMetaballsView.m
//
//  Created by Rolandas Razma on 24/10/2014.
//  Copyright (c) 2014 Rolandas Razma. All rights reserved.
//

#import "RRMetaballsView.h"
#import "UIImage+FloodFill.h"


struct RRMarchingSquare {
    int a;
    int b;
    int c;
    int d;
};
typedef struct RRMarchingSquare RRMarchingSquare;


#define RRMarchingSquareEdge0 0
#define RRMarchingSquareEdgeW 1
#define RRMarchingSquareEdgeS 2
#define RRMarchingSquareEdgeN 3
#define RRMarchingSquareEdgeE 4

#define pow2( __NUMBER__ ) ( (__NUMBER__) *(__NUMBER__) )


static inline float metaball(const float x, const float y, const RRBall *balls, const int ballsLength) {
    
    float sum = 0.0f;
    for ( int i = 0; i < ballsLength; i++ ) {
        RRBall ball = balls[i];
        float dx = x -ball.center.x;
        float dy = y -ball.center.y;
        
        float d2 = dx *dx +dy *dy;
        if( d2 != 0.0f ){
            sum += (ball.radius *ball.radius) /d2;
        }else{
            sum += 100000.0f;
        }
    }
    
    return sum;
}


/**
 * Linear interpolation function
 */
static inline float lerp (const float x0, const float x1, const float y0, const float y1, const float x) {
    if ( x0 == x1 ) {
        // return null
    }
    return y0 +(y1 -y0) *(x -x0) /(x1 -x0);
}


@implementation RRMetaballsView {
    RRMarchingSquare _cellTypeToMarchingSquare[16];
    
    float   _cellSize;
    float   _threshold;
    float   _colorThreshold;
    
    RRBall *_balls;
    int     _ballsMax;
    int     _ballsLength;
    
    BOOL    _needsRecalculate;
    
    int     _samplesRows;
    int     _samplesCols;
    float   *_samples;
    int     *_cellTypes;
}


#define INDEX(__ROW__, __COL__) ((__ROW__) +(__COL__) *_samplesRows)


#pragma mark -
#pragma mark NSObject (NSCoding)


- (id)initWithCoder:(NSCoder *)aDecoder {
    if( (self = [super initWithCoder:aDecoder]) ){
        [self setUp];
    }
    return self;
}


#pragma mark -
#pragma mark NSObject


- (id)init {
    if( (self = [super init]) ){
        [self setUp];
    }
    return self;
}


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


#pragma mark -
#pragma mark UIView


- (id)initWithFrame:(CGRect)frame {
    if( (self = [super initWithFrame:frame]) ){
        [self setUp];
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    
    if( _needsRecalculate ){
        [self recalculate];
    }
    
    [self drawContoursRect:rect inContext:UIGraphicsGetCurrentContext()];
    [self drawFillsForRect:rect inContext:UIGraphicsGetCurrentContext()];
    
}


#pragma mark -
#pragma mark RRMetaballsView


- (void)setUp {
    
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
    
    _cellSize           = 5.0f;
    _threshold          = 1.0f;
    _colorThreshold     = 0.0001f;
    
    _ballsMax           = 10;
    _balls              = malloc(_ballsMax *sizeof(*_balls));
    _ballsLength        = 0;
    
    _needsRecalculate   = YES;
    
    [self setBackgroundColor:[UIColor blackColor]];
}


- (void)setNeedsRecalculate {
    _needsRecalculate = YES;
}


- (void)addBall:(RRBall)ball {

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

    _balls[_ballsLength++] = ball;
    
    [self setNeedsRecalculate];
}


- (void)recalculate {

    int rows = ceil(self.bounds.size.height /_cellSize) +1;
    int cols = ceil(self.bounds.size.width  /_cellSize) +1;

    
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
        float y = row *_cellSize;
        
        for ( int col = 0; col < _samplesCols; col++ ) {
            float x = col *_cellSize;

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

    _needsRecalculate = NO;
    
}


- (void)drawContoursRect:(CGRect)rect inContext:(CGContextRef)contextRef {

    // DRAW CONTOUR
    CGMutablePathRef mutablePathRef = CGPathCreateMutable();
    
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
            compassCoords[RRMarchingSquareEdgeN] = CGPointMake((col +offsetN)   *_cellSize, row             *_cellSize);
            compassCoords[RRMarchingSquareEdgeW] = CGPointMake(col              *_cellSize, (row +offsetW)  *_cellSize);
            compassCoords[RRMarchingSquareEdgeE] = CGPointMake((col +1.0f)      *_cellSize, (row +offsetE)  *_cellSize);
            compassCoords[RRMarchingSquareEdgeS] = CGPointMake((col +offsetS)   *_cellSize, (row +1.0f)     *_cellSize);
            
            // 2 corners
            if ( !polyCompassCorners.c && !polyCompassCorners.d ) {
                NSAssert2(polyCompassCorners.a, @"Invalid corners: %i and %i", polyCompassCorners.a, polyCompassCorners.b);
                
                CGPoint startPoint = compassCoords[polyCompassCorners.a];
                CGPoint endPoint   = compassCoords[polyCompassCorners.b];

                CGPathMoveToPoint(mutablePathRef, NULL, startPoint.x, startPoint.y);
                CGPathAddLineToPoint(mutablePathRef, NULL, endPoint.x, endPoint.y);
            }
            // 4 corners
            else {
                // #1
                CGPoint startPoint = compassCoords[polyCompassCorners.a];
                CGPathMoveToPoint(mutablePathRef, NULL, startPoint.x, startPoint.y);
                
                CGPoint endPoint = compassCoords[polyCompassCorners.b];
                CGPathAddLineToPoint(mutablePathRef, NULL, endPoint.x, endPoint.y);
                
                // #2
                startPoint = compassCoords[polyCompassCorners.c];
                CGPathMoveToPoint(mutablePathRef, NULL, startPoint.x, startPoint.y);
                
                endPoint = compassCoords[polyCompassCorners.d];
                CGPathAddLineToPoint(mutablePathRef, NULL, endPoint.x, endPoint.y);
            }
        }
    }
    
    CGContextAddPath(contextRef, mutablePathRef);
    CGContextSetStrokeColorWithColor(contextRef, [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.01f].CGColor);
    CGContextDrawPath(contextRef, kCGPathStroke);
    
    CGPathRelease(mutablePathRef);

}


- (void)drawFillsForRect:(CGRect)rect inContext:(CGContextRef)contextRef {
    
    // fill border check can be made on different image to remove border and fix aliasing
    // https://developer.apple.com/library/mac/qa/qa1509/_index.html
    
    // FILL
    CGImageRef imgRef = CGBitmapContextCreateImage(contextRef);
    UIImage *img = [UIImage imageWithCGImage:imgRef];
    CGImageRelease(imgRef);

    NSUInteger fills = 0;
    __block NSUInteger fillPoints = 0;
    
    for( int i=0; i<_ballsLength; i++ ){
        RRBall ball = _balls[i];
    
        fills++;
        
        img = [img floodFillFromPoint: CGPointMake(ball.center.x *2.0f, ball.center.y *2.0f)
                            withColor: [UIColor whiteColor]
                      pixelColorBlock: ^(int x, int y, int *r, int *g, int *b, int *a) {
                          fillPoints++;
                          
                          // http://gynvael.coldwind.pl/download.php?f=metaballs.cpp
                          
                          // Setup some vars
                          float reached_thershold = 0.0f;
                          float rr = 0.0f, gg = 0.0f, bb = 0.0f;
                          
                          // For each metaball...
                          for( int k = 0; k < _ballsLength; k++ ){
                              
                              // Calculate the inverted squared distance
                              float dx = x -_balls[k].center.x *2.0f;
                              float dy = y -_balls[k].center.y *2.0f;
                              
                              float curr = 1.0f /(pow2(dx) +pow2(dy));
                              if( !dx && !dy ){
                                  // this circle was connected and should'n be used for 'i' loop
                                  // if ball touches another ball that was drawn there is no need to fill it
                                  // doesnt help to reduce number of points because after firs fill every point is already different so no flood can be made

//                                   curr = 1.0f; // <- endless loop with current fill, but removes center point
                                  NSLog(@"remove %i", k);
                              }

                              // Calculate reached threshold and colors
                              reached_thershold += curr;
                              
                              rr += _balls[k].colorR *curr;
                              gg += _balls[k].colorG *curr;
                              bb += _balls[k].colorB *curr;
                          }
                          
                          // Normalize the RGB vector (inverse square root - could use Quake tick)
                          float len = 1.0f /sqrtf(pow2(rr) +pow2(gg) +pow2(bb));
                          rr *= len;
                          gg *= len;
                          bb *= len;
                          
                          // Set the colors
                          if( reached_thershold >= _colorThreshold ){
                              *r = 255.0f *rr;
                              *g = 255.0f *gg;
                              *b = 255.0f *bb;
                          } else {
                              *r = 128.0f *rr;
                              *g = 128.0f *gg;
                              *b = 128.0f *bb;
                          }
                      }];
    }
    
    [img drawInRect:rect];
    
     NSLog(@"fills: %u fillPoints: %u", fills, fillPoints);
    // fills: 3 fillPoints: 87464
    // fills: 1 fillPoints: 87464

    
}


@end
