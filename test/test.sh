#!/bin/bash
set -e
NAME=build/war
LOGIN=rcabezas
function echo_green(){
    echo -e "\e[32m""${@}""\033[0m"
}

function echo_red(){
    echo -e "\e[31m""${@}""\033[0m"
}
function echo_blue(){
    echo -en "\e[94m""${@}""\033[0m" " "
}



function test_famine(){
    echo_blue Testing famine functionality
    mkdir -p /tmp/test
	mkdir -p /tmp/test2
	cp -f /bin/c* /tmp/test/
	./${NAME}
	strings /tmp/test/cp | grep $LOGIN >/dev/null || echo_red || KO
	/tmp/test/cp /bin/cp /tmp/test2/cp
	strings /tmp/test2/cp | grep -v $LOGIN >/dev/null || echo_red KO
	/tmp/test/cp --help 2>&1 >/dev/null
	strings /tmp/test2/cp | grep $LOGIN >/dev/null || echo_red KO
    echo_green OK
}

function test_hello_world(){
	echo_blue "Testing hello world integrity"
	mkdir -p /tmp/{test,test2}/
	gcc sample/sample.c -o /tmp/test/hello_world
	./$NAME
	gcc sample/sample.c -o /tmp/test2/hello_world

	/tmp/test/hello_world | grep Hello >/dev/null || echo_red KO
	strings /tmp/test/hello_world | grep $LOGIN > /dev/null && echo_green OK || echo_red KO
}

function test_ls(){
	echo_blue "Testing ls"
	mkdir -p /tmp/test/
	cp -f /bin/ls /tmp/test/ls
	./$NAME
	/tmp/test/ls -laR .. >/dev/null || echo_red KO
	echo_green OK

}

function kill_test() {
	local pids=$(ps -ef | tr -s " " | grep infinity | grep -v grep | cut -f2 -d' ')
	if [ $pids ]; then
		echo $pids | tr ' ' "\n" | xargs kill
	fi
}

function test_process_name(){
	echo_blue "Testing process detection "
    if [ ! -f /bin/test ]; then
		echo '#!/bin/sh' > /bin/test
		echo sleep infinity >> /bin/test
		chmod a+x /bin/test
    fi
	/bin/test &
	cp -f /bin/cp /tmp/test/cp
	if [ $(strings /tmp/test/cp | grep $LOGIN) ];then
		echo_red KO
	else
		./${NAME}
		strings /tmp/test/cp | grep $LOGIN >/dev/null && echo_red KO && kill_test && return -1 || true
		kill_test
		./${NAME}
		strings /tmp/test/cp | grep $LOGIN >/dev/null || echo_red KO
	fi

	kill_test
	rm -f /bin/test
	echo_green OK
	return 0
}

function test_antidebug(){
	cd test
	echo_blue Test anti debugging
	cp -f /bin/cp /bin/chmod /tmp/test
	cp -f /bin/ls /tmp/test2/ls
	gdb ../$NAME &>/dev/null
	local fail=false
	strings /tmp/test2/ls | grep $LOGIN > /dev/null && fail=true || fail=false
	if [ $fail == true ]; then
		echo_red KO
	else
		echo_green OK
	fi
	cd ..
}

function test_war(){
	war_md5=$(md5sum build/war | cut -f1 -d' ')

}

test_hello_world
test_ls
test_famine
test_process_name
test_antidebug
