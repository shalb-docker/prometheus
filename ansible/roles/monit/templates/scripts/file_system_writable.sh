#!/bin/bash

set -e

mount="$1"

date > ${mount}/monit_fs_write_test

