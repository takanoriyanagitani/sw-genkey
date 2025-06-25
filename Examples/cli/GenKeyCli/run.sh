#!/bin/sh

export ENV_SECRET_IKM_LOCATION=./sample.d/.secret/ikm.dat
export ENV_SECRET_PEPPER_LOCATION=./sample.d/.secret/pepper.dat

export ENV_PUBLIC_SALT_LOCATION=./sample.d/salt.dat
export ENV_PUBLIC_INFO_LOCATION=./sample.d/info.dat

test -f "${ENV_SECRET_IKM_LOCATION}" || exec sh -c '
  echo no input key material found.;
  exit 1
'

test -f "${ENV_SECRET_PEPPER_LOCATION}" || exec sh -c '
  echo no pepper data found.;
  exit 1
'

./GenKeyCli
