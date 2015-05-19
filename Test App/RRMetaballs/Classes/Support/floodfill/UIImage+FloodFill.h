//
//  UIImage+FloodFill.h
//  ImageFloodFilleDemo
//
//  Created by chintan on 15/07/13.
//  Copyright (c) 2013 ZWT. All rights reserved.
//

@import UIKit;
#import "LinkedListStack.h"


@interface UIImage (FloodFill)

- (UIImage *)floodFillFromPoint:(CGPoint)startPoint withColor:(UIColor *)newColor pixelColorBlock:(void (^)(int x, int y, int *r, int *g, int *b, int *a))pixelColorBlock;

@end