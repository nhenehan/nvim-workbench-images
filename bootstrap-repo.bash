#!/bin/env bash

rusty-tags vi

ctags -R .

find . -type f \
    ! -path "*/target/*" \
    > files.txt