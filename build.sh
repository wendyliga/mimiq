#!/bin/bash

if ! [ -f "mimiq.script" ]; then
    echo "missing mimiq file" && exit
fi

rm -f mimiq && cp mimiq.script mimiq && chmod +x mimiq
tar -zcvf mimiq.tar.gz mimiq