/*
 *  SEBuiltInPlugin.h
 *  Spark Editor
 *
 *  Created by Grayfox on 19/08/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkActionPlugIn.h>

@interface SEIgnorePlugin : SparkActionPlugIn {

}

- (int)type;

@end

@interface SEInheritsPlugin : SparkActionPlugIn {
  
}

- (int)type;

@end

