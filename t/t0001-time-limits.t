#!/bin/sh

test_description='Fluxion takes into account time limits'

. `dirname $0`/sharness.sh

hwloc_basepath=`readlink -e ${SHARNESS_TEST_SRCDIR}/data/hwloc-data`
# 1 node, 2 sockets, 44 cores (22 per socket), 4 gpus (2 per socket)
excl_1N1B="${hwloc_basepath}/001N/exclusive/01-brokers-sierra2"

skip_all_unless_have jq

export FLUX_SCHED_MODULE=none
test_under_flux 1

test_expect_success 'load test resources' '
    load_test_resources ${excl_1N1B}
'

test_expect_success 'loading fluxion modules works' '
    load_resource &&
    load_qmanager
'

test_expect_success 'a job with a time limit can be scheduled and run' '
    flux mini run -N 1 -n 1 --time-limit=5s sleep 3s
'

test_expect_success 'a job exceeding a time limit exits with non-zero exit code' '
    ! flux mini run -N 1 -n 1 --time-limit=5s sleep 13s
'

test_expect_success 'time limit specified is reflected in kvs resource.R' '
    limit=30
    fudge=2
    remaining=$(flux mini run -N 1 -n 1 --time-limit=${limit}s /g/g0/faaland1/projects/flux-get-remaining-time/remaining | awk "{print \$4}")
    test $remaining -ge $((limit - fudge)) && test $remaining -le $limit
'

test_expect_failure 'time limit specified is reflected in kvs resource.R of child job' '
    limit=30
    fudge=2
    remaining=$(flux mini run -N 1 -n 1 --time-limit=${limit}s flux mini run -N 1 -n 1 /g/g0/faaland1/projects/flux-get-remaining-time/remaining | awk "{print \$4}")
    test $remaining -ge $((limit - fudge)) && test $remaining -le $limit
'

test_expect_success 'cleanup active jobs' '
    cleanup_active_jobs
'

test_expect_success 'removing fluxion modules' '
    remove_qmanager &&
    remove_resource
'

test_done
