#!/bin/bash

find_tests() {
	./test_prettyping --list \
		| sed 's/^ *\([0-9]\+\):.*/\1/'
}

run_all_tests() {
	for test_id in $(find_tests); do
		./test_prettyping --test "${test_id}" --interval 1 \
			| ./add_timestamp_to_output.py --escape --digits 1
	done
}

run_all_tests | tee test_output.txt
echo
echo
echo
if [ -z "${DISPLAY}" ]; then
	#echo 'Please manually compare "test_output.txt" with "test_expected.txt".'
	diff test_expected.txt test_output.txt
else
	# Use any tool you want:
	meld test_expected.txt test_output.txt
	#kdiff3 test_expected.txt test_output.txt
	#gvimdiff test_expected.txt test_output.txt
fi
