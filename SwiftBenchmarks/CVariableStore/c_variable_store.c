#include "c_variable_store.h"

// ✅ Initialize the variable store
void init_variable_store(VariableStore* store) {
    store->value = 0;
}

// ✅ Set a value in the store
void set_variable(VariableStore* store, int new_value) {
    store->value = new_value;
}

// ✅ Retrieve a value from the store
int get_variable(VariableStore* store) {
    return store->value;
}
