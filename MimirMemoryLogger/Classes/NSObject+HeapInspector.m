//
//  NSObject+HeapInspector.m
//
//  Created by Christian Menschel on 06.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <libkern/OSAtomic.h>
#import <pthread.h>
#import <Foundation/Foundation.h>
#import "NSObject+HeapInspector.h"
#import <objc/runtime.h>
#include <execinfo.h>
#include <dlfcn.h>
#include <unistd.h>


static inline CFStringRef createCFString(const char *cStr)
{
    return CFStringCreateWithCString(NULL, cStr, kCFStringEncodingUTF8);
}

bool canRecordObject(id obj)
{
    if ([obj isProxy]) {
        // NSProxy sub classes will cause crash when calling class_getName on its class
        return false;
    }

    Class cls = object_getClass(obj);
    
    bool canRecord = true;
    CFStringRef className = createCFString(class_getName(cls));
    if (!className) {
        return false;
    }
    
    if (CFStringCompare(className, CFSTR("NSAutoreleasePool"), kCFCompareBackwards) == kCFCompareEqualTo) {
        return false;
    }

    return canRecord;
}
