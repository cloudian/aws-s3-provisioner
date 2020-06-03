#!/bin/bash -e

CREDENTIALS=$HOME/.aws/credentials

getcredential() {
  echo -n "$(awk "{ FS = \"[ ]?=[ ]?\" } ; \$1 == \"$1\" { print \$2 }" "$CREDENTIALS")"  | base64
}

AWS_ACCESS_KEY_ID=$(getcredential 'aws_access_key_id')
AWS_SECRET_ACCESS_KEY=$(getcredential 'aws_secret_access_key')

OWNER_SECRET_PATH=examples/owner-secret.yaml
OWNER_SECRET=$(dirname "$0")/../$OWNER_SECRET_PATH
TEMPFILE=$(mktemp)

grep -v "  AWS_ACCESS_KEY_ID" "$OWNER_SECRET" | grep -v "  AWS_SECRET_ACCESS_KEY" >"$TEMPFILE"
echo "  AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID" >>"$TEMPFILE"
echo "  AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY" >>"$TEMPFILE"
echo Updated $OWNER_SECRET_PATH from "$CREDENTIALS":
tail -n2 "$TEMPFILE"
mv "$TEMPFILE" "$OWNER_SECRET"
