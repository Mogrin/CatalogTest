//
//  TCLDirectory.h
//  TestCatalog
//
//  Created by Могрин on 10/19/14.
//  Copyright (c) 2014 Могрин. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@interface TCLDirectory : NSManagedObject

@property (nonatomic, retain) NSNumber *id;
@property (nonatomic, retain) NSNumber *parentId;
@property (nonatomic, retain) NSString *title;

@end
