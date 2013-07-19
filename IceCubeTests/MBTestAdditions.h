//
//  MBTestAdditions.h
//  IceCube
//
//  Created by Marian Bouček on 19.07.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#ifndef IceCube_MBTestAdditions_h
#define IceCube_MBTestAdditions_h

#define MBAssertEqualArrays(a1, a2, description, ...) \
do { \
  if (![a1 isEqualToArray:a2]) { \
    STFail(description); \
  \
  } \
} while(0) \

#endif
