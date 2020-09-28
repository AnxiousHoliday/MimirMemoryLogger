//
//  HeapStackInspector.h
//  Anghami Release
//
//  Created by Amer Eid on 9/24/20.
//  Copyright © 2020 Anghami. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^HeapEnumeratorBlock)(__unsafe_unretained id object, BOOL *stop);

@interface HeapStackInspector : NSObject
+ (NSDictionary *)heapSnapshot;

@end
