#!/usr/bin/env bash

cd starknet-foundry && \
cargo build --release && \
cd .. && \
./starknet-foundry/target/release/snforge test
