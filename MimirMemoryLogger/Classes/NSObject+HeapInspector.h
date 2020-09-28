//
//  NSObject+HeapInspector.h
//
//  Created by Christian Menschel on 06.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import <Foundation/Foundation.h>

extern bool canRecordObject(id obj);

@interface NSObject (HeapInspector)

@end
