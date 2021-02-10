
## tests that require too much memory
himem-tests = \
 @${1} test/sort.lua && \
 ${1} test/literals.lua && \
 ${1} test/pm.lua && \
 ${1} test/nextvar.lua && \
 ${1} test/gc.lua && \
 ${1} test/calls.lua && \
 ${1} test/constructs.lua && \
 ${1} test/json.lua

determinism-tests = \
	test/deterministic_random_test.sh ${1}

lowmem-tests = \
		@${1} test/vararg.lua && \
		${1} test/utf8.lua && \
		${1} test/tpack.lua && \
		${1} test/strings.lua && \
		${1} test/math.lua && \
		${1} test/goto.lua && \
		${1} test/events.lua && \
		${1} test/code.lua && \
		${1} test/locals.lua

# removed for memory usage in wasm
#	    ${1} test/coroutine.lua

# ECP arithmetic test vectors from milagro, removed from normal tests
# since in zenroom built without debug is not allowed to import an ECP
# from x/y coords.
# ${1} test/ecp_bls383.lua && \
# ${1} test/big_bls383.lua && \
# ${1} test/ecdsa_vectors.lua && \

crypto-tests = \
	@${1} test/octet.lua && \
	${1} test/octet_conversion.lua && \
	${1} test/hash.lua && \
	${1} test/ecdh.lua && \
	${1} test/dh_session.lua && \
	${1} test/nist/aes_gcm.lua && \
	${1} test/nist/aes_cbc.lua && \
	${1} test/nist/aes_ctr.lua && \
	${1} test/ecp_generic.lua && \
	${1} test/elgamal.lua && \
	${1} test/bls_pairing.lua && \
	${1} test/coconut_test.lua && \
	${1} test/crypto_abc_zeta.lua

crypto-integration = \
	test/octet-json.sh ${1} && \
	cd test/nist && ./run.sh ../../${1}; cd -; \
	test/integration_asymmetric_crypto.sh ${1}

# TODO: complete with tamale and date
lua-modules = \
	@${1} test/faces.lua && \
	${1} test/slaxml.lua

zencode-integration = \
	./test/zencode_parser.sh && \
	cd test/zencode_cookbook && ./run-all.sh; cd -; \
	cd test/zencode_given && ./run.sh; cd -; \
	cd test/zencode_numbers && ./run.sh; cd -; \
	cd test/zencode_array && ./run.sh; cd -; \
	cd test/zencode_hash && ./run.sh; cd -; \
	cd test/zencode_ecdh && ./run.sh; cd -; \
	cd test/zencode_credential && ./run.sh; cd -; \
	cd test/zencode_petition && ./run.sh; cd -;


# ${1} test/closure.lua && \

# failing js tests due to larger memory required:
# abort("Cannot enlarge memory arrays. Either (1) compile with -s
# TOTAL_MEMORY=X with X higher than the current value 16777216, (2)
# compile with -s ALLOW_MEMORY_GROWTH=1 which allows increasing the
# size at runtime but prevents some optimizations, (3) set
# Module.TOTAL_MEMORY to a higher value before the program runs, or
# (4) if you want malloc to return NULL (0) instead of this abort,
# compile with -s ABORTING_MALLOC=0 ") at Error
# himem:
#  ${1} test/constructs.lua && \
#  ${1} test/cjson-test.lua
# lowmem:
#  ${1} test/coroutine.lua && \

# these all pass but require cjson_full to run
# 	${test-exec} test/cjson-test.lua

# these require the debug extension too much
# ${test-exec} test/coroutine.lua

# these may serve to verify the boundary of maximum memory
# since some trigger warnings when compiled with full debug
# $(call himem-tests,${test-exec})

check:
	@echo "Test target 'check' supports various modes, please specify one:"
	@echo "\t check-linux, check-osx, check-js check-py"
	@echo "\t check-debug, check-crypto, debug-crypto"

check-osx: test-exec := ./src/zenroom.command
check-osx:
	rm -f /tmp/zenroom-test-summary.txt
	${test-exec} test/constructs.lua
	$(call lowmem-tests,${test-exec})
	$(call determinism-tests,${test-exec})
	$(call crypto-tests,${test-exec})
	$(call zencode-tests,${test-exec})
	$(call crypto-integration,${test-exec})
	$(call zencode-integration,${test-exec})
	@echo "----------------"
	@echo "All tests passed for OSX binary build"
	@echo "----------------"

check-linux: test-exec := ./src/zenroom
check-linux:
	rm -f /tmp/zenroom-test-summary.txt
	${test-exec} test/constructs.lua
	$(call himem-tests,${test-exec})
	$(call lowmem-tests,${test-exec})
	$(call determinism-tests,${test-exec})
	$(call crypto-tests,${test-exec})
	$(call zencode-tests,${test-exec})
	$(call crypto-integration,${test-exec})
	$(call zencode-integration,${test-exec})
	cat /tmp/zenroom-test-summary.txt
	@echo "----------------"
	@echo "All tests passed for LINUX binary build"
	@echo "----------------"


check-js: test-exec := node ${pwd}/test/zenroom_exec.js ${pwd}/src/zenroom.js
check-js:
	$(call lowmem-tests,${test-exec})
	$(call crypto-tests,${test-exec})
	$(call zencode-tests,${test-exec})
	@echo "----------------"
	@echo "All tests passed for JS binary build"
	@echo "----------------"

check-py: test-exec := python3 ${pwd}/test/zenroom_exec.py ${pwd}
check-py:
	$(call lowmem-tests,${test-exec})
	$(call crypto-tests,${test-exec})
	$(call zencode-tests,${test-exec})
	@echo "----------------"
	@echo "All tests passed for PYTHON build"
	@echo "----------------"

check-debug: test-exec := valgrind --max-stackframe=5000000 ${pwd}/src/zenroom -d 3
check-debug:
	rm -f /tmp/zenroom-test-summary.txt
	$(call lowmem-tests,${test-exec})
	$(call crypto-tests,${test-exec})
	$(call zencode-tests,${test-exec})
	cat /tmp/zenroom-test-summary.txt
	@echo "----------------"
	@echo "All tests passed for DEBUG binary build"
	@echo "----------------"

# $(call determinism-tests,${test-exec})

check-crypto: test-exec := ./src/zenroom
check-crypto:
	rm -f /tmp/zenroom-test-summary.txt
	$(call determinism-tests,${test-exec})
	$(call crypto-tests,${test-exec})
	$(call zencode-tests,${test-exec})
	$(call crypto-integration,${test-exec})
	$(call zencode-integration,${test-exec})
	cat /tmp/zenroom-test-summary.txt
	@echo "-----------------------"
	@echo "All CRYPTO tests passed"
	@echo "-----------------------"

check-crypto-lw: test-exec := ./src/zenroom -c memmanager=lw
check-crypto-lw:
	rm -f /tmp/zenroom-test-summary.txt
	$(call determinism-tests,${test-exec})
	$(call crypto-tests,${test-exec})
	$(call zencode-tests,${test-exec})
	$(call zencode-integration,${test-exec})
	cat /tmp/zenroom-test-summary.txt
	@echo "-----------------------"
	@echo "All CRYPTO tests passed with lw memory manager"
	@echo "-----------------------"


check-crypto-stb: test-exec := ./src/zenroom -c print=stb
check-crypto-stb:
	rm -f /tmp/zenroom-test-summary.txt
	$(call determinism-tests,${test-exec})
	$(call crypto-tests,${test-exec})
	$(call zencode-tests,${test-exec})
	$(call zencode-integration,${test-exec})
	cat /tmp/zenroom-test-summary.txt
	@echo "-----------------------"
	@echo "All CRYPTO tests passed with lw memory manager"
	@echo "-----------------------"

check-crypto-mutt: test-exec := ./src/zenroom -c print=mutt
check-crypto-mutt:
	rm -f /tmp/zenroom-test-summary.txt
	$(call determinism-tests,${test-exec})
	$(call crypto-tests,${test-exec})
	$(call zencode-tests,${test-exec})
	$(call zencode-integration,${test-exec})
	cat /tmp/zenroom-test-summary.txt
	@echo "-----------------------"
	@echo "All CRYPTO tests passed with lw memory manager"
	@echo "-----------------------"

check-crypto-debug: test-exec := valgrind --max-stackframe=5000000 ${pwd}/src/zenroom -d 3
check-crypto-debug:
	rm -f /tmp/zenroom-test-summary.txt
	$(call determinism-tests,${test-exec})
	$(call crypto-tests,${test-exec})
	$(call zencode-tests,${test-exec})
	cat /tmp/zenroom-test-summary.txt


#	./test/integration_asymmetric_crypto.sh ${test-exec}

#	./test/octet-json.sh ${test-exec}

