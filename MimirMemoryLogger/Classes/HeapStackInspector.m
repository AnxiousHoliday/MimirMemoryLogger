//
//  HeapStackInspector.m
//  Anghami Release
//
//  Created by Amer Eid on 9/24/20.
//  Copyright © 2020 Anghami. All rights reserved.
//

#import "HeapStackInspector.h"
#import <malloc/malloc.h>
#import <mach/mach.h>
#import <objc/runtime.h>
#import "NSObject+HeapInspector.h"

static CFMutableSetRef classesLoadedInRuntime = NULL;

// Mimics the objective-c object stucture for checking if a range of memory is an object.
typedef struct {
    Class isa;
} rm_maybe_object_t;

@implementation HeapStackInspector

static inline kern_return_t memory_reader(task_t task, vm_address_t remote_address, vm_size_t size, void **local_memory) {
    *local_memory = (void *)remote_address;
    return KERN_SUCCESS;
}

static inline void range_callback(task_t task, void *context, unsigned type, vm_range_t *ranges, unsigned rangeCount) {
    HeapEnumeratorBlock enumeratorBlock = (__bridge HeapEnumeratorBlock)context;
    if (!enumeratorBlock) {
        return;
    }
    BOOL stop = NO;
    for (unsigned int i = 0; i < rangeCount; i++) {
        vm_range_t range = ranges[i];
        rm_maybe_object_t *object = (rm_maybe_object_t *)range.address;
        Class tryClass = NULL;
#ifdef __arm64__
        // See http://www.sealiesoftware.com/blog/archive/2013/09/24/objc_explain_Non-pointer_isa.html
        extern uint64_t objc_debug_isa_class_mask WEAK_IMPORT_ATTRIBUTE;
        tryClass = (__bridge Class)((void *)((uint64_t)object->isa & objc_debug_isa_class_mask));
#else
        tryClass = object->isa;
#endif
        if (tryClass &&
            CFSetContainsValue(classesLoadedInRuntime, (__bridge const void *)(tryClass)) &&
            canRecordObject((__bridge id)object)) {
            enumeratorBlock((__bridge id)object, &stop);
            if (stop) {
                break;
            }
        }
    }
}

+ (void)enumerateLiveObjectsUsingBlock:(HeapEnumeratorBlock)completionBlock {
    if (!completionBlock) {
        return;
    }
    // Refresh the class list on every call in case classes are added to the runtime.
    [self updateRegisteredClasses];

    // For another exmple of enumerating through malloc ranges (which helped my understanding of the api) see:
    // http://llvm.org/svn/llvm-project/lldb/tags/RELEASE_34/final/examples/darwin/heap_find/heap/heap_find.cpp
    // Also https://gist.github.com/samdmarshall/17f4e66b5e2e579fd396
    // or http://www.opensource.apple.com/source/Libc/Libc-167/gen.subproj/malloc.c
    vm_address_t *zones = NULL;
    mach_port_t task = mach_task_self();
    unsigned int zoneCount = 0;
    kern_return_t result = malloc_get_all_zones(task, memory_reader, &zones, &zoneCount);
    BOOL __block stopEnumerator = NO;
    if (result == KERN_SUCCESS) {
        for (unsigned i = 0; i < zoneCount; i++) {
            malloc_zone_t *zone = (malloc_zone_t *)zones[i];
            if (zone != NULL
                && !zone->reserved1 && !zone->reserved2 // if reserved1 and reserved2 are not NULL, zone object is corrupted
                && zone->introspect != NULL && zone->introspect->enumerator != NULL) {
                HeapEnumeratorBlock enumeratorBlock = ^(__unsafe_unretained id object, BOOL *stop) {
                    completionBlock(object, &stopEnumerator);
                    if (stopEnumerator) {
                        *stop = YES;
                    }
                };
                if (!stopEnumerator) {
                    zone->introspect->enumerator(task,
                                                 (__bridge void *)(enumeratorBlock),
                                                 MALLOC_PTR_IN_USE_RANGE_TYPE,
                                                 (vm_address_t)zone,
                                                 memory_reader,
                                                 range_callback);
                } else {
                    break;
                }
            }
        }
    }
}

+ (void)updateRegisteredClasses
{
    if (!classesLoadedInRuntime) {
        classesLoadedInRuntime = CFSetCreateMutable(NULL, 0, NULL);
    } else {
        CFSetRemoveAllValues(classesLoadedInRuntime);
    }
    unsigned int count = 0;
    Class *classes = objc_copyClassList(&count);
    for (unsigned int i = 0; i < count; i++) {
        CFSetAddValue(classesLoadedInRuntime, (__bridge const void *)(classes[i]));
    }
    free(classes);
}

#pragma mark - Public

+ (NSDictionary *)heapSnapshot
{
    NSMutableDictionary* response = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* objects = [[NSMutableDictionary alloc] init];
    
    static NSString* TOTALSIZE = @"totalSize";
    static NSString* NUMBEROFINSTANCES = @"numberOfInstances";
    static NSString* MAXSINGLEINSTANCESIZE = @"maxSingleInstanceSize";
    
    __block unsigned long totalSize = 0;
    [HeapStackInspector enumerateLiveObjectsUsingBlock:^(__unsafe_unretained id object, BOOL *stop) {
        unsigned long sizeOfCurrentObject = malloc_size((__bridge const void *)(object));
        totalSize = totalSize + sizeOfCurrentObject;
        
        NSString *className = [NSString stringWithFormat:@"%s", object_getClassName(object)];
        
        if (objects[className] && [objects[className] isKindOfClass:NSMutableDictionary.class]) {
            NSMutableDictionary* existingObjectDictionary = (NSMutableDictionary*)objects[className];
            NSNumber *existingTotalSize = @(0);
            NSNumber *existingNumberOfInstances = @(0);
            NSNumber *existingMaxSingleInstanceSize = @(0);
            if (existingObjectDictionary[TOTALSIZE] && [existingObjectDictionary[TOTALSIZE] isKindOfClass:NSNumber.class]) {
                existingTotalSize = (NSNumber*)existingObjectDictionary[TOTALSIZE];
            }
            if (existingObjectDictionary[NUMBEROFINSTANCES] && [existingObjectDictionary[NUMBEROFINSTANCES] isKindOfClass:NSNumber.class]) {
                existingNumberOfInstances = (NSNumber*)existingObjectDictionary[NUMBEROFINSTANCES];
            }
            if (existingObjectDictionary[MAXSINGLEINSTANCESIZE] && [existingObjectDictionary[MAXSINGLEINSTANCESIZE] isKindOfClass:NSNumber.class]) {
                existingMaxSingleInstanceSize = (NSNumber*)existingObjectDictionary[MAXSINGLEINSTANCESIZE];
            }
            NSNumber *newTotalSize = @(existingTotalSize.unsignedLongValue + sizeOfCurrentObject);
            NSNumber *newNumberOfInstances = @(existingNumberOfInstances.unsignedLongValue + 1);
            NSNumber *newMaxSingleInstanceSize= @(sizeOfCurrentObject > existingMaxSingleInstanceSize.unsignedLongValue ? sizeOfCurrentObject : existingMaxSingleInstanceSize.unsignedLongValue);
            objects[className] = [NSMutableDictionary dictionaryWithDictionary:@{TOTALSIZE: newTotalSize,
                                                                                 NUMBEROFINSTANCES: newNumberOfInstances,
                                                                                 MAXSINGLEINSTANCESIZE: newMaxSingleInstanceSize
            }];
        } else {
            objects[className] = [NSMutableDictionary dictionaryWithDictionary:@{TOTALSIZE: @(sizeOfCurrentObject),
                                                                                 NUMBEROFINSTANCES: @(1),
                                                                                 MAXSINGLEINSTANCESIZE: @(sizeOfCurrentObject)
            }];
        }
    }];
    NSMutableArray<NSDictionary*> *objectsArray = [NSMutableArray<NSDictionary*> array];
    [objects enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL* stop) {
        if ([value isKindOfClass:NSDictionary.class] && [key isKindOfClass:NSString.class]) {
            NSString* className = (NSString*)key;
            NSDictionary* objectDictionary = (NSDictionary*)value;
            NSNumber *totalSize = @(0);
            NSNumber *numberOfInstances = @(0);
            NSNumber *maxSingleInstanceSize = @(0);
            if (objectDictionary[TOTALSIZE] && [objectDictionary[TOTALSIZE] isKindOfClass:NSNumber.class]) {
                totalSize = (NSNumber*)objectDictionary[TOTALSIZE];
            }
            if (objectDictionary[NUMBEROFINSTANCES] && [objectDictionary[NUMBEROFINSTANCES] isKindOfClass:NSNumber.class]) {
                numberOfInstances = (NSNumber*)objectDictionary[NUMBEROFINSTANCES];
            }
            if (objectDictionary[MAXSINGLEINSTANCESIZE] && [objectDictionary[MAXSINGLEINSTANCESIZE] isKindOfClass:NSNumber.class]) {
                maxSingleInstanceSize = (NSNumber*)objectDictionary[MAXSINGLEINSTANCESIZE];
            }
            NSDictionary* fullObjectDictionary = @{TOTALSIZE: totalSize,
                                                   NUMBEROFINSTANCES: numberOfInstances,
                                                   MAXSINGLEINSTANCESIZE: maxSingleInstanceSize,
                                                   @"className": className
            };
            [objectsArray addObject:fullObjectDictionary];
        }
    }];
    response[@"totalSize"] = @(totalSize);
    response[@"objectsInMemory"] = objectsArray;
    response[@"dateSnapshotWasTaken"] = @([[NSDate date] timeIntervalSince1970]);
    return response;
}

@end

