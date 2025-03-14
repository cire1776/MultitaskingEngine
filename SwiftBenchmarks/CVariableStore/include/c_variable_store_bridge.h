//
//  c_variable_store_bridge.h
//  
//
//  Created by Eric Russell on 3/4/25.
//

#ifndef C_VARIABLE_STORE_BRIDGE_H
#define C_VARIABLE_STORE_BRIDGE_H

#include "c_variable_store.h"

// ✅ Bridge functions for Swift interop
void init_variable_store_bridge(void);
void set_variable_bridge(int new_value);
int get_variable_bridge(void);

#endif
