//
//  RRMetaballsView.m
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

#import "RRMetaballsView.h"
#import "RRMetaballsViewAnimationBlockDelegate.h"
#import "RRMetaball.h"


@implementation RRMetaballsView {
    NSMutableArray  *_metaballs;
    NSMutableArray  *_animationBlockDelegates;
    BOOL            _willAnimate;
}


#pragma mark -
#pragma mark NSObject


- (instancetype)init {
    if ( (self = [super init]) ) {
        [self.layer setContentsScale: [[UIScreen mainScreen] scale]];
    }
    
    return self;
}


#pragma mark -
#pragma mark NSCoding


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ( (self = [super initWithCoder:aDecoder]) ) {
        [self.layer setContentsScale: [[UIScreen mainScreen] scale]];
    }
    
    return self;
}


#pragma mark -
#pragma mark UIView


+ (Class)layerClass {
    return [RRMetaballsLayer class];
}


- (instancetype)initWithFrame:(CGRect)frame {
    if ( (self = [super initWithFrame:frame]) ) {
        [self.layer setContentsScale: [[UIScreen mainScreen] scale]];
    }
    
    return self;
}


#pragma mark -
#pragma mark CALayerDelegate


- (id <CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)key {
    
    if( [layer isEqual:self.layer] && layer.presentationLayer != nil ){
        if( [key isEqualToString:@"cellSize"] || [key isEqualToString:@"centers"] || [key isEqualToString:@"radiuses"] || [key isEqualToString:@"colors"] ){
            CABasicAnimation *basicAnimation = [CABasicAnimation animationWithKeyPath:key];
            [basicAnimation setFillMode: kCAFillModeBoth];
            [basicAnimation setFromValue: [layer.presentationLayer valueForKey:key]];
            [basicAnimation setDelegate: [_animationBlockDelegates lastObject]];
            
            return basicAnimation;
        }
    }
    
    return [super actionForLayer:layer forKey:key];
}


#pragma mark -
#pragma mark RRMetaballsView


- (NSArray *)metabals {
    return [_metaballs copy];
}


- (void)addMetabal:(RRMetaball *)metabal {
    
    NSMutableArray *centers = ((self.layer.centers) ? [self.layer.centers   mutableCopy] : [NSMutableArray array]);
    NSMutableArray *radiuses= ((self.layer.radiuses)? [self.layer.radiuses  mutableCopy] : [NSMutableArray array]);
    NSMutableArray *colors  = ((self.layer.colors)  ? [self.layer.colors    mutableCopy] : [NSMutableArray array]);
    
    if( [_metaballs containsObject:metabal] ){
        NSUInteger index = [_metaballs indexOfObject:metabal];
        
        // Remove object
        [_metaballs[index] removeObserver:self forKeyPath:@"center"];
        [_metaballs[index] removeObserver:self forKeyPath:@"radius"];
        [_metaballs[index] removeObserver:self forKeyPath:@"color"];
        
        [_metaballs removeObjectAtIndex:index];
        [centers    removeObjectAtIndex:index];
        [radiuses   removeObjectAtIndex:index];
        [colors     removeObjectAtIndex:index];
    }
    
    if( !_metaballs ){
        _metaballs = [NSMutableArray array];
    }
    
    // Add object
    [_metaballs addObject: metabal];
    [centers    addObject: [NSValue valueWithCGPoint: metabal.center]];
    [radiuses   addObject: @(metabal.radius)];
    [colors     addObject: (id)metabal.color.CGColor];
    
    // Update layer
    [self.layer setCenters: centers];
    [self.layer setRadiuses: radiuses];
    [self.layer setColors: colors];
    
    [metabal addObserver:self forKeyPath:@"center"  options:NSKeyValueObservingOptionNew context:NULL];
    [metabal addObserver:self forKeyPath:@"radius"  options:NSKeyValueObservingOptionNew context:NULL];
    [metabal addObserver:self forKeyPath:@"color"   options:NSKeyValueObservingOptionNew context:NULL];
}


- (void)removeMetabal:(RRMetaball *)metabal {

    if( ![_metaballs containsObject:metabal] ) return;
    
    NSMutableArray *centers = [self.layer.centers   mutableCopy];
    NSMutableArray *radiuses= [self.layer.radiuses  mutableCopy];
    NSMutableArray *colors  = [self.layer.colors    mutableCopy];
    
    NSUInteger index = [_metaballs indexOfObject:metabal];
    
    // Remove object
    [_metaballs[index] removeObserver:self forKeyPath:@"center"];
    [_metaballs[index] removeObserver:self forKeyPath:@"radius"];
    [_metaballs[index] removeObserver:self forKeyPath:@"color"];
    
    [_metaballs removeObjectAtIndex:index];
    [centers    removeObjectAtIndex:index];
    [radiuses   removeObjectAtIndex:index];
    [colors     removeObjectAtIndex:index];
    
    // Update layer
    [self.layer setCenters: centers];
    [self.layer setRadiuses: radiuses];
    [self.layer setColors: colors];

}


- (void)animateMetabalsWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations {
    [self animateMetabalsWithDuration: duration
                           animations: animations
                           completion: NULL];
}


- (void)animateMetabalsWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion {
    
    if( !_animationBlockDelegates ){
        _animationBlockDelegates = [NSMutableArray array];
    }

    _willAnimate = YES;
    
    
    RRMetaballsViewAnimationBlockDelegate *animationBlockDelegate = [RRMetaballsViewAnimationBlockDelegate new];
    [animationBlockDelegate setCompletion: completion];
    [_animationBlockDelegates addObject: animationBlockDelegate];
    
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:duration];
    [CATransaction setAnimationTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut]];
    
    animations();
    
    NSMutableArray *centers = [self.layer.centers   mutableCopy];
    NSMutableArray *radiuses= [self.layer.radiuses  mutableCopy];
    NSMutableArray *colors  = [self.layer.colors    mutableCopy];

    [_metaballs enumerateObjectsUsingBlock: ^(RRMetaball *metabal, NSUInteger index, BOOL *stop) {
        // center
        centers[index]  = [NSValue valueWithCGPoint: metabal.center];
        
        // radius
        radiuses[index] = @(metabal.radius);
        
        // color
        colors[index]   = (id)metabal.color.CGColor;
    }];
    
    [self.layer setCenters: centers];
    [self.layer setRadiuses: radiuses];
    [self.layer setColors: colors];

    [CATransaction commit];

    _willAnimate = NO;
    
    [_animationBlockDelegates removeLastObject];
    
}


#pragma mark -
#pragma mark NSKeyValueObserving


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(RRMetaball *)metaball change:(NSDictionary *)change context:(void *)context {
    
    if( _willAnimate ) return;

    BOOL isActionsDisabled = [CATransaction disableActions];
    [CATransaction setDisableActions:YES];
    
    // center
    if( [keyPath isEqualToString:@"center"] ){
        NSMutableArray *centers = [self.layer.centers mutableCopy];
        centers[[_metaballs indexOfObject:metaball]] = [NSValue valueWithCGPoint: metaball.center];
        [self.layer setCenters: centers];
    }
    
    // radius
    else if( [keyPath isEqualToString:@"radius"] ){
        NSMutableArray *radiuses = [self.layer.radiuses mutableCopy];
        radiuses[[_metaballs indexOfObject:metaball]] = @(metaball.radius);
        [self.layer setRadiuses: radiuses];
    }
    
    // color
    else if( [keyPath isEqualToString:@"color"] ){
        NSMutableArray *colors = [self.layer.colors mutableCopy];
        colors[[_metaballs indexOfObject:metaball]] = (id)metaball.color.CGColor;
        [self.layer setColors: colors];
    }
    
    [CATransaction setDisableActions:isActionsDisabled];
    
}


@dynamic layer;
@end
