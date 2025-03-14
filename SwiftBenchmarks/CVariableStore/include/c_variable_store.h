//
//  c_variable_store.h
//  
//
//  Created by Eric Russell on 3/4/25.
//

#ifndef C_VARIABLE_STORE_H
#define C_VARIABLE_STORE_H

#include <stdbool.h>

// ✅ Define a simple struct-based key-value store
typedef struct {
    int value;
} VariableStore;

// ✅ Function declarations
void init_variable_store(VariableStore* store);
void set_variable(VariableStore* store, int new_value);
int get_variable(VariableStore* store);

#endif
