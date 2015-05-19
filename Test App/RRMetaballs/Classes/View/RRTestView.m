//
//  RRTestView.m
//  RRMetaballs
//
//  Created by Rolandas Razma on 24/10/2014.
//  Copyright (c) 2014 Rolandas Razma. All rights reserved.
//

#import "RRTestView.h"


#define IS_POINT_IN_CIRCLE(__POINT__, __CENTER__, __R__) (powf(__POINT__.x -__CENTER__.x, 2.0f)+ powf(__POINT__.y -__CENTER__.y, 2.0f) < powf((__R__), 2.0f))


@implementation RRTestView


#pragma mark -
#pragma mark UIResponder


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesMoved:touches withEvent:event];
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

    for( UITouch *touch in touches ){
        CGPoint locationInView = [touch locationInView:self];

        for( int i=0; i<self.ballsLength; i++ ){
            if( IS_POINT_IN_CIRCLE(locationInView, self.balls[i].center, self.balls[i].radius) ){
                self.balls[i].center = CGPointMake(roundf(locationInView.x), roundf(locationInView.y));
                
                [self setNeedsRecalculate];
                [self setNeedsDisplay];
                
                break;
            }
        }
    }

}


@end
