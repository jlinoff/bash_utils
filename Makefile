#
# Test utils.sh.
#

all: test

rel: ~/bin/utils.sh

~/bin/utils.sh : utils.sh
	@cp -v $< $@

clean:
	rm -f *~ test.out*

test:
	@echo "Testing"
	@./test.sh >test.out 2>&1
	@sed -r	-e 's/ elapsed=.*/ elapsed=x/' \
		-e 's/^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]*/%date %time/' \
		-e 's/Cmd Pwd: .*$$/Cmd Pwd: x/' \
		test.out >test.out.flt
	@sed -r	-e 's/ elapsed=.*/ elapsed=x/' \
		-e 's/^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]*/%date %time/' \
		-e 's/Cmd Pwd: .*$$/Cmd Pwd: x/' \
		test.gold >test.gold.flt
	@-diff test.out.flt test.gold.flt ; \
	Status=$$? ; \
	if (( $$Status )) ; then echo "FAILED" ; else echo "PASSED" ; fi

