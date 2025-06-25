#!/bin/sh

docdir=./doc.d
port=62180
addr=127.0.0.1

python3 \
	-m http.server \
	--bind "${addr}" \
	--directory "${docdir}" \
	${port}
