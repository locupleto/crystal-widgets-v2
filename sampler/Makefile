CFLAGS = -O2 -Wall -Wextra

crystal_sampler: crystal_sampler.c
	clang $(CFLAGS) -arch arm64 -arch x86_64 -o $@ $<

clean:
	rm -f crystal_sampler

.PHONY: clean
