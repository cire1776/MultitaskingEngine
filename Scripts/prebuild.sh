#!/bin/sh

//  prebuild.sh
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/10/25.
//

#!/bin/sh
echo "🚀 [Pre-Build] Running prebuild.sh at $(date)"

# Print all environment variables for debugging
env

# Check if PROJECT_ROOT is set
if [ -z "$PROJECT_ROOT" ]; then
    echo "❌ PROJECT_ROOT is NOT set!"
else
    echo "✅ PROJECT_ROOT: $PROJECT_ROOT"
fi

# Save to log file for persistent debugging
#echo "PROJECT_ROOT=$PROJECT_ROOT" > prebuild_env.log
