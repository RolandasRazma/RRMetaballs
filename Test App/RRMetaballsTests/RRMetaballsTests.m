//
//  RRMetaballsTests.m
//  RRMetaballsTests
//
//  Created by Rolandas Razma on 08/10/2014.
//  Copyright (c) 2014 Rolandas Razma. All rights reserved.
//

@import UIKit;
@import XCTest;
#import "RRMetaballsView.h"


@interface RRMetaballsView (RRPrivate)

- (void)recalculate;
- (void)drawContoursRect:(CGRect)rect inContext:(CGContextRef)contextRef;
- (void)drawFillsForRect:(CGRect)rect inContext:(CGContextRef)contextRef;

@end


@interface RRMetaballsTests : XCTestCase

@end


@implementation RRMetaballsTests {
    RRMetaballsView *_metaballsView;
}


#pragma mark -
#pragma mark XCTestCase


- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _metaballsView = [[RRMetaballsView alloc] initWithFrame:CGRectMake(0, 0, 320.0f, 480.0f)];
}


- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    _metaballsView = nil;
    
    [super tearDown];
}


#pragma mark -
#pragma mark RRMetaballsTests


- (void)saveImageFromCurrentImageContextToFile:(NSString *)file {
    [UIImageJPEGRepresentation(UIGraphicsGetImageFromCurrentImageContext(), 1.0f) writeToFile:file atomically:YES];
}


//- (void)testRecalculateNotConnectedPerformance {
//
//    [_metaballsView addBall:  RRBallMake( CGPointMake((320 /2) -100, (480 /2)     ), 40, [UIColor  redColor] )];
//    [_metaballsView addBall:  RRBallMake( CGPointMake((320 /2) +100, (480 /2)     ), 40, [UIColor greenColor] )];
//    [_metaballsView addBall:  RRBallMake( CGPointMake((320 /2)     , (480 /2) +100), 40, [UIColor  blueColor] )];
//    
//    [self measureBlock: ^{
//        [_metaballsView recalculate];
//    }];
//    
//}


//- (void)testDrawContoursNotConnectedPerformance {
//    
//    [_metaballsView addBall:  RRBallMake( CGPointMake((320 /2) -100, (480 /2)     ), 40, [UIColor  redColor] )];
//    [_metaballsView addBall:  RRBallMake( CGPointMake((320 /2) +100, (480 /2)     ), 40, [UIColor greenColor] )];
//    [_metaballsView addBall:  RRBallMake( CGPointMake((320 /2)     , (480 /2) +100), 40, [UIColor  blueColor] )];
//    
//    [_metaballsView recalculate];
//
//    [self measureBlock: ^{
//        
//        UIGraphicsBeginImageContextWithOptions(_metaballsView.bounds.size, NO, 0.0f);
//        
//        [_metaballsView drawContoursRect:_metaballsView.bounds inContext:UIGraphicsGetCurrentContext()];
//
//        UIGraphicsEndImageContext();
//
//    }];
//
//}


//- (void)testDrawFillsNotConnectedPerformance {
//    
//    [_metaballsView addBall:  RRBallMake( CGPointMake((320 /2) -100, (480 /2)     ), 40, [UIColor  redColor] )];
//    [_metaballsView addBall:  RRBallMake( CGPointMake((320 /2) +100, (480 /2)     ), 40, [UIColor greenColor] )];
//    [_metaballsView addBall:  RRBallMake( CGPointMake((320 /2)     , (480 /2) +100), 40, [UIColor  blueColor] )];
//    
//    [_metaballsView recalculate];
//    
//    UIGraphicsBeginImageContextWithOptions(_metaballsView.bounds.size, NO, 0.0f);
//    [_metaballsView drawContoursRect:_metaballsView.bounds inContext:UIGraphicsGetCurrentContext()];
//    
//    [self measureBlock: ^{
//        [_metaballsView drawFillsForRect:_metaballsView.bounds inContext:UIGraphicsGetCurrentContext()];
//        [self saveImageFromCurrentImageContextToFile:@"/Users/GameBit/Desktop/testDrawFillsNotConnectedPerformance.jpg"];
//        NSLog(@"x");
//    }];
//    
//}


//- (void)testRecalculateConnectedPerformance {
//    
//    [_metaballsView addBall:  RRBallMake( CGPointMake((320 /2) -70, (480 /2)    ), 40, [UIColor  redColor] )];
//    [_metaballsView addBall:  RRBallMake( CGPointMake((320 /2) +70, (480 /2)    ), 40, [UIColor greenColor] )];
//    [_metaballsView addBall:  RRBallMake( CGPointMake((320 /2)    , (480 /2) +70), 40, [UIColor  blueColor] )];
//
//    [self measureBlock: ^{
//        [_metaballsView recalculate];
//    }];
//    
//}


//- (void)testDrawConnectedPerformance {
//    
//    [_metaballsView addBall:  RRBallMake( CGPointMake((320 /2) -70, (480 /2)    ), 40, [UIColor  redColor] )];
//    [_metaballsView addBall:  RRBallMake( CGPointMake((320 /2) +70, (480 /2)    ), 40, [UIColor greenColor] )];
//    [_metaballsView addBall:  RRBallMake( CGPointMake((320 /2)    , (480 /2) +70), 40, [UIColor  blueColor] )];
//
//    [_metaballsView recalculate];
//
//    [self measureBlock: ^{
//        UIGraphicsBeginImageContextWithOptions(_metaballsView.bounds.size, NO, 0.0f);
//        
//        [_metaballsView drawContoursRect:_metaballsView.bounds inContext:UIGraphicsGetCurrentContext()];
//
//        UIGraphicsEndImageContext();
//    }];
//    
//}
//
//
//- (void)testDrawFillConnectedPerformance {
//    
//    [_metaballsView addBall:  RRBallMake( CGPointMake((320 /2) -70, (480 /2)    ), 40, [UIColor  redColor] )];
//    [_metaballsView addBall:  RRBallMake( CGPointMake((320 /2) +70, (480 /2)    ), 40, [UIColor greenColor] )];
//    [_metaballsView addBall:  RRBallMake( CGPointMake((320 /2)    , (480 /2) +70), 40, [UIColor  blueColor] )];
//    
//    [_metaballsView recalculate];
//    
//    UIGraphicsBeginImageContextWithOptions(_metaballsView.bounds.size, NO, 0.0f);
//    [_metaballsView drawContoursRect:_metaballsView.bounds inContext:UIGraphicsGetCurrentContext()];
//    
//    [self saveImageFromCurrentImageContextToFile:@"/Users/GameBit/Desktop/testDrawPerformance_r.jpg"];
//    
//    [self measureBlock: ^{
//
//        [_metaballsView drawFillsForRect:_metaballsView.bounds inContext:UIGraphicsGetCurrentContext()];
//        
//        [self saveImageFromCurrentImageContextToFile:@"/Users/GameBit/Desktop/testDrawPerformance_f.jpg"];
//        
//        NSLog(@"xx");
//
//    }];
//    
//}


@end
