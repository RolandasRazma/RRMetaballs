//
//  RRMetaballsView.h
//
//  Created by Rolandas Razma on 24/10/2014.
//  Copyright (c) 2014 Rolandas Razma. All rights reserved.
//

@import UIKit;


struct RRBall {
    CGPoint center;
    float   radius;
    
    CGFloat colorR;
    CGFloat colorG;
    CGFloat colorB;
    CGFloat colorA;
};
typedef struct RRBall RRBall;


static inline RRBall RRBallMake(CGPoint center, const float radius, UIColor *color) {
    RRBall ball;
    ball.center = center;
    ball.radius = radius;

    const CGFloat *components = CGColorGetComponents(color.CGColor);
    if( CGColorGetNumberOfComponents(color.CGColor) == 2 ) {
        ball.colorR = ball.colorG = ball.colorB = components[0];
        ball.colorA = components[1];
    } else if ( CGColorGetNumberOfComponents(color.CGColor) == 4 ) {
        ball.colorR = components[0];
        ball.colorG = components[1];
        ball.colorB = components[2];
        ball.colorA = components[3];
    }

    return ball;
}


@interface RRMetaballsView : UIView

@property (nonatomic, readonly) RRBall *balls;
@property (nonatomic, readonly) int     ballsLength;

- (void)setNeedsRecalculate;

- (void)addBall:(RRBall)ball;

@end
