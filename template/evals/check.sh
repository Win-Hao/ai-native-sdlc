#!/bin/bash
# check.sh <eval.json> <result.json> — run the eval's checks, exit non-zero on failure.
E="$1"; R="$2"; FAIL=0
name=$(jq -r '.id' "$E")
n=$(jq '.checks | length' "$E")
for i in $(seq 0 $((n-1))); do
  t=$(jq -r ".checks[$i].type" "$E")
  case "$t" in
    command)
      cmd=$(jq -r ".checks[$i].run" "$E"); want=$(jq -r ".checks[$i].expect_exit // 0" "$E")
      eval "$cmd" >/dev/null 2>&1; got=$?
      [ "$got" = "$want" ] || { echo "FAIL $name check[$i] command '$cmd' exit=$got want=$want"; FAIL=1; } ;;
    grep)
      p=$(jq -r ".checks[$i].path" "$E"); s=$(jq -r ".checks[$i].expect" "$E")
      grep -qF -- "$s" "$p" 2>/dev/null || { echo "FAIL $name check[$i] '$s' not in $p"; FAIL=1; } ;;
    not_grep)
      p=$(jq -r ".checks[$i].path" "$E"); s=$(jq -r ".checks[$i].expect" "$E")
      grep -qF -- "$s" "$p" 2>/dev/null && { echo "FAIL $name check[$i] '$s' present in $p"; FAIL=1; } ;;
    policy)
      # Model-graded: a check a script cannot make. Reported, never silently passed.
      echo "MANUAL $name check[$i] policy=$(jq -r ".checks[$i].skill" "$E") expect=$(jq -r ".checks[$i].expect" "$E")" ;;
    *) echo "FAIL $name check[$i] unknown type '$t'"; FAIL=1 ;;
  esac
done
[ $FAIL -eq 0 ] && echo "PASS $name"
exit $FAIL
