#!/bin/sh
# Tests against hand-computed textbook numbers. Extend this file as you
# implement policies (e.g. SJF/SRTF/PRIO/MLFQ on arrivals.txt, your own
# paging and disk workloads).
#
# A check whose command stops with "not implemented yet" prints SKIP: the
# expected value is already here, waiting for your implementation. Every SKIP
# must have become PASS by the deadline of its checkpoint.
BIN=./ossim
fail=0; pass=0; skip=0

check() {   # check <description> <command> <expected-word>
    out=$($2 2>&1)
    status=$?
    if echo "$out" | grep -q "not implemented yet"; then
        echo "SKIP  $1"; skip=$((skip + 1))
    elif [ "$status" -eq 0 ] && echo "$out" | grep -Fqw -- "$3"; then
        echo "PASS  $1"; pass=$((pass + 1))
    else
        echo "FAIL  $1"; echo "      expected: $3"; echo "$out" | sed 's/^/      /'; fail=1
    fi
}

check_no() {   # check_no <description> <command> <word that must NOT appear>
    out=$($2 2>&1)
    status=$?
    if echo "$out" | grep -q "not implemented yet"; then
        echo "SKIP  $1"; skip=$((skip + 1))
    elif [ "$status" -ne 0 ]; then
        echo "FAIL  $1 (exit $status)"; echo "$out" | sed 's/^/      /'; fail=1
    elif echo "$out" | grep -Fqw -- "$3"; then
        echo "FAIL  $1"; echo "      must not contain: $3"; echo "$out" | sed 's/^/      /'; fail=1
    else
        echo "PASS  $1"; pass=$((pass + 1))
    fi
}

# --- reference policies (must pass from day one) --------------------------
check "FCFS textbook example: avg waiting 17.00" \
      "$BIN workloads/basic.txt --sched fcfs --no-paging" "avg_waiting=17.00"

check "RR q=4 textbook example: avg waiting 5.67" \
      "$BIN workloads/basic.txt --sched rr --quantum 4 --no-paging" "avg_waiting=5.67"

check "RR q=4: context switches = 4 (P1,P2,P3,P1)" \
      "$BIN workloads/basic.txt --sched rr --quantum 4 --no-paging" "context_switches=4"

check "Paging: P1 alone, FIFO, 3 frames -> 15 faults (textbook Sec. 10.4.2)" \
      "$BIN workloads/paging_p1.txt --frames 3 --replace fifo" "page_faults=15"

check "Disk: FCFS, head 53 -> 640 cylinders (textbook Sec. 11.2.1)" \
      "$BIN workloads/disk_textbook.txt --no-paging --head 53 --disk fcfs" "head_movement=640"

check "Producer/consumer completes" \
      "$BIN workloads/producer_consumer.txt --sched rr --quantum 2 --no-paging" "finished=2/2"

check "Deadlock workload without detection: A and B stall, C finishes" \
      "$BIN workloads/deadlock.txt --sched rr --quantum 2 --max-ticks 60 --no-paging" "finished=1/3"

check "Mixed workload finishes" \
      "$BIN workloads/mixed.txt --sched rr --quantum 3 --frames 6" "finished=4/4"

check "Mixed workload finishes with 1 frame (faults wait for a frame)" \
      "$BIN workloads/mixed.txt --sched rr --quantum 3 --frames 1" "finished=4/4"

# --- checkpoint 1 ----------------------------------------------------------
check "Deadlock detection reports A and B (pids 1 2)" \
      "$BIN workloads/deadlock.txt --sched rr --quantum 2 --deadlock-every 5 --max-ticks 60 --no-paging" "pids: 1 2"

# Hand-computed in docs/checks/deadlock.md.
check "Deadlock detection: first found at the check of t=15" \
      "$BIN workloads/deadlock.txt --sched rr --quantum 2 --deadlock-every 5 --max-ticks 60 --no-paging" "DEADLOCK t=15 pids: 1 2"
check_no "Deadlock detection: reported once, not again at t=20" \
      "$BIN workloads/deadlock.txt --sched rr --quantum 2 --deadlock-every 5 --max-ticks 60 --no-paging" "DEADLOCK t=20"
check_no "Deadlock detection (2 instances): no report at t=4, B can still finish" \
      "$BIN workloads/deadlock_multi.txt --sched rr --quantum 1 --deadlock-every 2 --max-ticks 20 --no-paging" "DEADLOCK t=4"
check "Deadlock detection (2 instances): found at t=6" \
      "$BIN workloads/deadlock_multi.txt --sched rr --quantum 1 --deadlock-every 2 --max-ticks 20 --no-paging" "DEADLOCK t=6 pids: 1 2"
check_no "Deadlock detection (2 instances): blocked but not deadlocked" \
      "$BIN workloads/no_deadlock_multi.txt --sched fcfs --deadlock-every 1 --no-paging" "DEADLOCK"
check "Deadlock detection (2 instances): non-deadlocked processes finish" \
      "$BIN workloads/no_deadlock_multi.txt --sched fcfs --deadlock-every 1 --no-paging" "finished=2/2"

for s in sjf srtf prio mlfq; do
    check "Producer/consumer completes under $s" \
          "$BIN workloads/producer_consumer.txt --sched $s --quantum 2 --no-paging" "finished=2/2"
done
# Person A: independent calculations and Gantt charts in docs/checks/.
check "SJF on arrivals: avg waiting 10.00 (hand-computed)" \
      "$BIN workloads/arrivals.txt --sched sjf --no-paging" "avg_waiting=10.00"
check "SJF on arrivals: avg response 9.00 (hand-computed)" \
      "$BIN workloads/arrivals.txt --sched sjf --no-paging" "avg_response=9.00"
check "SJF on arrivals: avg turnaround 17.83 (hand-computed)" \
      "$BIN workloads/arrivals.txt --sched sjf --no-paging" "avg_turnaround=17.83"
check "SJF on arrivals: 8 context switches (hand-computed)" \
      "$BIN workloads/arrivals.txt --sched sjf --no-paging" "context_switches=8"

check "SRTF on arrivals: avg waiting 9.83 (hand-computed)" \
      "$BIN workloads/arrivals.txt --sched srtf --no-paging" "avg_waiting=9.83"
check "SRTF on arrivals: avg response 9.00 (hand-computed)" \
      "$BIN workloads/arrivals.txt --sched srtf --no-paging" "avg_response=9.00"
check "SRTF on arrivals: avg turnaround 17.67 (hand-computed)" \
      "$BIN workloads/arrivals.txt --sched srtf --no-paging" "avg_turnaround=17.67"
check "SRTF on arrivals: 9 context switches (hand-computed)" \
      "$BIN workloads/arrivals.txt --sched srtf --no-paging" "context_switches=9"

check "PRIO q=2 on arrivals: avg waiting 12.83 (hand-computed)" \
      "$BIN workloads/arrivals.txt --sched prio --quantum 2 --no-paging" "avg_waiting=12.83"
check "PRIO q=2 on arrivals: avg response 8.33 (hand-computed)" \
      "$BIN workloads/arrivals.txt --sched prio --quantum 2 --no-paging" "avg_response=8.33"
check "PRIO q=2 on arrivals: avg turnaround 20.67 (hand-computed)" \
      "$BIN workloads/arrivals.txt --sched prio --quantum 2 --no-paging" "avg_turnaround=20.67"
check "PRIO q=2 on arrivals: 12 context switches (hand-computed)" \
      "$BIN workloads/arrivals.txt --sched prio --quantum 2 --no-paging" "context_switches=12"

check "SJF textbook bursts 24,3,3: avg waiting 3.00" \
      "$BIN workloads/basic.txt --sched sjf --no-paging" "avg_waiting=3.00"

# These cases distinguish FIFO ties from pid order, and check that cpu
# ops back to back retain the CPU (and PRIO's quantum) without a dispatch.
check "SJF edge case: avg waiting 3.50" \
      "$BIN workloads/sched_edges.txt --sched sjf --no-paging" "avg_waiting=3.50"
check "SJF edge case: avg response 3.75" \
      "$BIN workloads/sched_edges.txt --sched sjf --no-paging" "avg_response=3.75"
check "SJF edge case: avg turnaround 6.25" \
      "$BIN workloads/sched_edges.txt --sched sjf --no-paging" "avg_turnaround=6.25"
check "SJF edge case: 4 context switches" \
      "$BIN workloads/sched_edges.txt --sched sjf --no-paging" "context_switches=4"

check "SRTF edge case: avg waiting 2.75" \
      "$BIN workloads/sched_edges.txt --sched srtf --no-paging" "avg_waiting=2.75"
check "SRTF edge case: avg response 1.50" \
      "$BIN workloads/sched_edges.txt --sched srtf --no-paging" "avg_response=1.50"
check "SRTF edge case: avg turnaround 5.50" \
      "$BIN workloads/sched_edges.txt --sched srtf --no-paging" "avg_turnaround=5.50"
check "SRTF edge case: 5 context switches" \
      "$BIN workloads/sched_edges.txt --sched srtf --no-paging" "context_switches=5"

check "PRIO q=2 edge case: avg waiting 3.50" \
      "$BIN workloads/sched_edges.txt --sched prio --quantum 2 --no-paging" "avg_waiting=3.50"
check "PRIO q=2 edge case: avg response 2.25" \
      "$BIN workloads/sched_edges.txt --sched prio --quantum 2 --no-paging" "avg_response=2.25"
check "PRIO q=2 edge case: avg turnaround 6.25" \
      "$BIN workloads/sched_edges.txt --sched prio --quantum 2 --no-paging" "avg_turnaround=6.25"
check "PRIO q=2 edge case: 5 context switches" \
      "$BIN workloads/sched_edges.txt --sched prio --quantum 2 --no-paging" "context_switches=5"

check "PRIO q=3: equal arrivals wait, fresh quantum after preemption; waiting 6.00" \
      "$BIN workloads/prio_check.txt --sched prio --quantum 3 --no-paging" "avg_waiting=6.00"
check "PRIO q=3: avg response 3.75" \
      "$BIN workloads/prio_check.txt --sched prio --quantum 3 --no-paging" "avg_response=3.75"
check "PRIO q=3: avg turnaround 9.50" \
      "$BIN workloads/prio_check.txt --sched prio --quantum 3 --no-paging" "avg_turnaround=9.50"
check "PRIO q=3: 7 context switches" \
      "$BIN workloads/prio_check.txt --sched prio --quantum 3 --no-paging" "context_switches=7"

for s in sjf srtf prio; do
    check "Mixed workload finishes under $s with paging" \
          "$BIN workloads/mixed.txt --sched $s --quantum 3 --frames 6" "finished=4/4"
    check "Mixed workload finishes under $s with one frame" \
          "$BIN workloads/mixed.txt --sched $s --quantum 3 --frames 1" "finished=4/4"
done
# Person B: MLFQ, hand-computed in docs/checks/mlfq.md.
check "MLFQ q=2 on arrivals: avg waiting 15.33 (hand-computed)" \
      "$BIN workloads/arrivals.txt --sched mlfq --quantum 2 --no-paging" "avg_waiting=15.33"
check "MLFQ q=2 on arrivals: avg response 0.00 (hand-computed)" \
      "$BIN workloads/arrivals.txt --sched mlfq --quantum 2 --no-paging" "avg_response=0.00"
check "MLFQ q=2 on arrivals: avg turnaround 23.17 (hand-computed)" \
      "$BIN workloads/arrivals.txt --sched mlfq --quantum 2 --no-paging" "avg_turnaround=23.17"
check "MLFQ q=2 on arrivals: 19 context switches (hand-computed)" \
      "$BIN workloads/arrivals.txt --sched mlfq --quantum 2 --no-paging" "context_switches=19"

# Bottom level, keeping the CPU alone, and a boost that delays C.
check "MLFQ edge case: avg waiting 1.67" \
      "$BIN workloads/mlfq_check.txt --sched mlfq --quantum 2 --no-paging" "avg_waiting=1.67"
check "MLFQ edge case: avg response 0.33 (boost puts A back on level 0)" \
      "$BIN workloads/mlfq_check.txt --sched mlfq --quantum 2 --no-paging" "avg_response=0.33"
check "MLFQ edge case: avg turnaround 13.00" \
      "$BIN workloads/mlfq_check.txt --sched mlfq --quantum 2 --no-paging" "avg_turnaround=13.00"
check "MLFQ edge case: 5 context switches" \
      "$BIN workloads/mlfq_check.txt --sched mlfq --quantum 2 --no-paging" "context_switches=5"
check "Mixed workload finishes under mlfq with paging" \
      "$BIN workloads/mixed.txt --sched mlfq --quantum 3 --frames 6" "finished=4/4"
check "Mixed workload finishes under mlfq with one frame" \
      "$BIN workloads/mixed.txt --sched mlfq --quantum 3 --frames 1" "finished=4/4"

# --- checkpoint 2 ----------------------------------------------------------
check "Paging: LRU, 3 frames -> 12 faults (textbook Sec. 10.4.4)" \
      "$BIN workloads/paging_p1.txt --frames 3 --replace lru" "page_faults=12"
# TODO: a Clock case you computed by hand (the textbook has none, make one).

check "Disk: SSTF, head 53 -> 236" \
      "$BIN workloads/disk_textbook.txt --no-paging --head 53 --disk sstf" "head_movement=236"
check "Disk: SCAN moving down, head 53 -> 236" \
      "$BIN workloads/disk_textbook.txt --no-paging --head 53 --direction down --disk scan" "head_movement=236"
check "Disk: C-LOOK moving up, head 53 -> 322" \
      "$BIN workloads/disk_textbook.txt --no-paging --head 53 --direction up --disk clook" "head_movement=322"

echo "---"
echo "$pass passed, $skip skipped (not implemented yet), $([ $fail = 0 ] && echo 0 || echo some) failed"
exit $fail
