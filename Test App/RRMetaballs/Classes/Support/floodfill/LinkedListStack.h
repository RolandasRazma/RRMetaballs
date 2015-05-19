//
//  LinkedList.h
//  NSDataLinkedList
//
//  Created by Sam Davies on 26/09/2012.
//  Copyright (c) 2012 VisualPutty. All rights reserved.
//

@import Foundation;

#define FINAL_NODE_OFFSET -1
#define INVALID_NODE_CONTENT INT_MIN

typedef struct PointNode {
    int nextNodeOffset;
    int point;
} PointNode;


@interface LinkedListStack : NSObject

- (id)initWithCapacity:(int)capacity incrementSize:(int)increment andMultiplier:(int)mul;
- (id)initWithCapacity:(int)capacity;

- (void)pushFrontX:(int)x andY:(int)y;
- (int)popFront:(int *)x andY:(int *)y;

@end
