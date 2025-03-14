//
//  c_variable_store_bridge.h
//  
//
//  Created by Eric Russell on 3/4/25.
//

#include "c_variable_store_bridge.h"

// ✅ Create a global VariableStore instance
static VariableStore global_store;

void init_variable_store_bridge() {
    init_variable_store(&global_store);
}

void set_variable_bridge(int new_value) {
    set_variable(&global_store, new_value);
}

int get_variable_bridge() {
    return get_variable(&global_store);
}
