#!/bin/sh

ssh $1 "cd $2;git diff -p"|git apply
