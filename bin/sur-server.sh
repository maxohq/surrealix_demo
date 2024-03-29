#!/usr/bin/env bash

# surreal start --auth --user root --pass root --bind 0.0.0.0:8000 memory
# surreal start --auth --user root --pass root --bind 0.0.0.0:8000 --allow-scripting  --allow-funcs --allow-net memory

# --log trace \
surreal start \
    --auth \
    --user root \
    --pass root \
    --allow-scripting \
    --allow-funcs \
    --allow-net \
    --bind 0.0.0.0:8000 \
    file:data/sur-demo.db
