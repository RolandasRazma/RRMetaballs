//
//  RRTestView.m
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

#import "RRTestView.h"
#import "RRMetaball.h"


#define pow2( __NUMBER__ ) ( (__NUMBER__) *(__NUMBER__) )
#define IS_POINT_IN_CIRCLE(__POINT__, __CENTER__, __R__) (pow2(__POINT__.x -__CENTER__.x)+ pow2(__POINT__.y -__CENTER__.y) < pow2(__R__))


@implementation RRTestView {
    UIView      *_activeView;
    RRMetaball  *_activeMetaball;
}


#pragma mark -
#pragma mark UIResponder


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];

    // Remove all animations
    [self.layer removeAllAnimations];
    
    // Touch location
    CGPoint locationInView = [[touches anyObject] locationInView:self];
    
    // Pick up metaball
    if( !_activeMetaball ){

        [self.subviews enumerateObjectsUsingBlock: ^(UIView *view, NSUInteger idx, BOOL *stop) {
            if( CGRectContainsPoint(view.frame, locationInView) ){
                RRMetaball *metaball = self.metabals[view.tag];
                
                if( IS_POINT_IN_CIRCLE(locationInView, metaball.center, metaball.radius) ){
                    [self setActiveView:view];
                    *stop = YES;
                }
            }
        }];

    }
    
    // Put down metaball
    else {

        [self animateMetabalsWithDuration: 1.0f
                               animations: ^{
                                   [_activeMetaball setCenter: locationInView];
                                   
                                   // Keep in mind that animations are not synchronized
                                   [UIView animateWithDuration: 1.0f
                                                    animations: ^{
                                                        [_activeView setCenter: locationInView];
                                                    }];
                               }];
        
        [self setActiveView:nil];
    }

}


#pragma mark -
#pragma mark UIView


- (void)addSubview:(UIView *)view {
    [super addSubview: view];

    // Skip Apple stuff
    if( [NSStringFromClass(view.class) characterAtIndex:0] == '_' ) return;

    // Create RRMetaball
    RRMetaball *metaball = [RRMetaball metaballWithCenter: view.center
                                                   radius: MAX(CGRectGetWidth(view.frame), CGRectGetHeight(view.frame)) /2.0f
                                                    color: view.backgroundColor];
    
    [self addMetabal: metaball];

    // Store index of metaball
    [view setTag: [self.metabals indexOfObject:metaball]];
    
    // Remove background from view (background will come from metaball itself)
    [view setBackgroundColor: [UIColor clearColor]];
    
}


#pragma mark -
#pragma mark RRTestView


- (void)setActiveView:(UIView *)activeView {
    RRMetaball *activeMetaball = ((activeView)?self.metabals[activeView.tag]:nil);

    if( activeMetaball ){
        // Pulsate active metaball
        NSMutableArray *radiuses = [self.layer.radiuses mutableCopy];
        radiuses[[self.metabals indexOfObject:activeMetaball]] = @(MAX(CGRectGetWidth(activeView.frame), CGRectGetHeight(activeView.frame)) /2.0f +2.0f);
        
        CABasicAnimation *basicAnimation = [CABasicAnimation animationWithKeyPath:@"radiuses"];
        [basicAnimation setDuration: 0.31f];
        [basicAnimation setAutoreverses:YES];
        [basicAnimation setRepeatCount: HUGE_VALF];
        [basicAnimation setFromValue: [self.layer.presentationLayer valueForKey:@"radiuses"]];
        [basicAnimation setToValue: radiuses];
        
        [self.layer addAnimation:basicAnimation forKey:@"radiuses"];
    }
    
    _activeView     = activeView;
    _activeMetaball = activeMetaball;
    
}


@end
