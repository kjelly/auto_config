#! /usr/bin/env bash
tmp_worksapce=$RANDOM
i3-msg "rename workspace $1 to $tmp_worksapce"
i3-msg "rename workspace $2 to $1"
i3-msg "rename workspace $tmp_worksapce to $2"
