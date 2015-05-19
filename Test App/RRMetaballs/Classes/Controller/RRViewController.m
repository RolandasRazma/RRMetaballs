//
//  RRViewController.m
//  RRMetaballs
//
//  Created by Rolandas Razma on 08/10/2014.
//  Copyright (c) 2014 Rolandas Razma. All rights reserved.
//

#import "RRViewController.h"


@implementation RRViewController


#pragma mark -
#pragma mark UIViewController


- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view addBall:  RRBallMake( CGPointMake((320 /2) -70, (480 /2)     ), 40, [UIColor  redColor] )];
    [self.view addBall:  RRBallMake( CGPointMake((320 /2) +70, (480 /2)     ), 40, [UIColor greenColor] )];
    [self.view addBall:  RRBallMake( CGPointMake((320 /2)    , (480 /2) +70), 40, [UIColor  blueColor] )];
    
//    [self.view addBall:  RRBallMake( CGPointMake((320 /2), (480 /2)), 40, [UIColor   redColor] )];
//    [self.view addBall:  RRBallMake( CGPointMake((320 /2), (480 /2)), 40, [UIColor greenColor] )];
//    [self.view addBall:  RRBallMake( CGPointMake((320 /2), (480 /2)), 40, [UIColor  blueColor] )];

}


@end
