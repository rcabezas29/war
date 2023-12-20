#!/bin/bash
set -e
NAME=build/pestilence
LOGIN=rcabezas
function echo_green(){
    echo -e "\e[32m""${@}""\033[0m"
}

function echo_red(){
    echo -e "\e[31m""${@}""\033[0m"
}
function echo_blue(){
    echo -e "\e[94m""${@}""\033[0m"
}


function test_famine(){
    echo_blue Testing famine functionality
    mkdir -p /tmp/test
	mkdir -p /tmp/test2
	cp /bin/c* /tmp/test/
	./${NAME}
	strings /tmp/test/cp | grep $LOGIN >/dev/null || echo_red || KO
	/tmp/test/cp /bin/cp /tmp/test2/cp
	strings /tmp/test2/cp | grep -v $LOGIN >/dev/null || echo_red KO
	/tmp/test/cp --help 2>&1 >/dev/null
	strings /tmp/test2/cp | grep $LOGIN >/dev/null || echo_red KO
    echo_green OK
}

function test_anti_debugging(){
    if [ ! -f sample/test ]; then

    fi
}

test_famine