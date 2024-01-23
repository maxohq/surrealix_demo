#!/usr/bin/env bash

echo "DOWNLOAD the demo data set from https://surrealdb.com/docs/surrealql/demo!"
surreal import \
    --conn http://0.0.0.0:8000 \
    --user root \
    --pass root \
    --ns demo \
    --db deal \
    data/surreal_deal_v1.surql

echo "IMPORTED TO demo/deal. 'use db deal' to switch!"
