#!/usr/bin/env bash
fmt="$(tmux show -gv 'status-format[0]')"
tmux set -g 'status-format[0]' "${fmt/'#[nolist align=right'/'#{?@branch, #{@branch} ,}#[nolist align=right'}"
