/*
 * sched.c: CPU schedulers.
 *
 * FCFS and RR are given. SJF, SRTF, PRIO and MLFQ are implemented below.
 * Each one is a scheduler_t with the same hooks as FCFS and RR. There are
 * notes above each stub. Functions you will probably need:
 *   proc_burst_remaining(p)   ticks left in p's current cpu burst
 *   proc_total_remaining(p)   cpu ticks left in the whole process
 *   q_pop_min(&q, key)        remove the element with the smallest key
 *   q_min_key(&q, key)        the smallest key, without removing (for preemption)
 */
#include <string.h>
#include "sched.h"
#include "queue.h"
#include "kernel.h"

scheduler_t *sched = NULL;

/* FCFS */
static queue_t fcfs_q;

static void   fcfs_init(void)                { q_init(&fcfs_q); }
static void   fcfs_enqueue(pcb_t *p)         { q_push(&fcfs_q, p); }
static bool   fcfs_should_preempt(pcb_t *r)  { (void)r; return false; }
static pcb_t *fcfs_pick(void)                { return q_pop(&fcfs_q); }
static void   fcfs_on_dispatch(pcb_t *p)     { (void)p; }
static void   fcfs_on_tick(pcb_t *r)         { (void)r; }
static int    fcfs_ready_count(void)         { return q_size(&fcfs_q); }

static scheduler_t sched_fcfs = {
    "fcfs", fcfs_init, fcfs_enqueue, fcfs_should_preempt, fcfs_pick,
    fcfs_on_dispatch, fcfs_on_tick, fcfs_ready_count
};

/* RR */
static queue_t rr_q;

static void   rr_init(void)            { q_init(&rr_q); }
static void   rr_enqueue(pcb_t *p)     { q_push(&rr_q, p); }
static pcb_t *rr_pick(void)            { return q_pop(&rr_q); }
static void   rr_on_dispatch(pcb_t *p) { p->quantum_used = 0; }
static void   rr_on_tick(pcb_t *r)     { r->quantum_used++; }
static int    rr_ready_count(void)     { return q_size(&rr_q); }

/* Preempt when the quantum is used up and someone else is ready. If nobody
 * is ready, the process keeps the CPU and starts a new quantum, so a process
 * that arrives later waits until that quantum is over. */
static bool rr_should_preempt(pcb_t *r)
{
    if (r->quantum_used < cfg.quantum) return false;
    r->quantum_used = 0;
    return !q_empty(&rr_q);
}

static scheduler_t sched_rr = {
    "rr", rr_init, rr_enqueue, rr_should_preempt, rr_pick,
    rr_on_dispatch, rr_on_tick, rr_ready_count
};

/* SJF: use the current burst, not all remaining CPU work. q_pop_min()
 * preserves ready-queue order on ties (DECISION.md D-7). */
static queue_t sjf_q;

static int    burst_key(const pcb_t *p)    { return proc_burst_remaining(p); }
static void   sjf_init(void)               { q_init(&sjf_q); }
static void   sjf_enqueue(pcb_t *p)        { q_push(&sjf_q, p); }
static bool   sjf_should_preempt(pcb_t *r) { (void)r; return false; }
static pcb_t *sjf_pick(void)               { return q_pop_min(&sjf_q, burst_key); }
static void   sjf_on_dispatch(pcb_t *p)    { (void)p; }
static void   sjf_on_tick(pcb_t *r)        { (void)r; }
static int    sjf_ready_count(void)        { return q_size(&sjf_q); }

static scheduler_t sched_sjf = {
    "sjf", sjf_init, sjf_enqueue, sjf_should_preempt, sjf_pick,
    sjf_on_dispatch, sjf_on_tick, sjf_ready_count
};

/* SRTF: equal remaining bursts do not preempt the running process. */
static queue_t srtf_q;

static void   srtf_init(void)            { q_init(&srtf_q); }
static void   srtf_enqueue(pcb_t *p)     { q_push(&srtf_q, p); }
static pcb_t *srtf_pick(void)            { return q_pop_min(&srtf_q, burst_key); }
static void   srtf_on_dispatch(pcb_t *p) { (void)p; }
static void   srtf_on_tick(pcb_t *r)     { (void)r; }
static int    srtf_ready_count(void)     { return q_size(&srtf_q); }

static bool srtf_should_preempt(pcb_t *r)
{
    return q_min_key(&srtf_q, burst_key) < burst_key(r);
}

static scheduler_t sched_srtf = {
    "srtf", srtf_init, srtf_enqueue, srtf_should_preempt, srtf_pick,
    srtf_on_dispatch, srtf_on_tick, srtf_ready_count
};

/* PRIO: a smaller number is a higher priority. A dispatch starts a fresh
 * quantum, including after higher-priority preemption (DECISION.md D-8). */
static queue_t prio_q;

static int    prio_key(const pcb_t *p)   { return p->priority; }
static void   prio_init(void)            { q_init(&prio_q); }
static void   prio_enqueue(pcb_t *p)     { q_push(&prio_q, p); }
static pcb_t *prio_pick(void)            { return q_pop_min(&prio_q, prio_key); }
static void   prio_on_dispatch(pcb_t *p) { p->quantum_used = 0; }
static void   prio_on_tick(pcb_t *r)     { r->quantum_used++; }
static int    prio_ready_count(void)     { return q_size(&prio_q); }

static bool prio_should_preempt(pcb_t *r)
{
    int best = q_min_key(&prio_q, prio_key);
    if (best < r->priority) return true;
    if (r->quantum_used < cfg.quantum) return false;

    /* Lower-priority waiters must not take the CPU on quantum expiry. */
    r->quantum_used = 0;
    return !q_empty(&prio_q) && best == r->priority;
}

static scheduler_t sched_prio = {
    "prio", prio_init, prio_enqueue, prio_should_preempt, prio_pick,
    prio_on_dispatch, prio_on_tick, prio_ready_count
};

/* MLFQ: three RR levels with quanta q, 2q and 4q (DECISION.md D-10).
 * A process is demoted in on_tick, as soon as it has used its whole
 * quantum, so it is demoted even if it blocks in that same tick. A process
 * that blocks earlier keeps its level. Every MLFQ_BOOST ticks everyone goes
 * back to level 0. */
#define MLFQ_LEVELS 3
#define MLFQ_BOOST  20

static queue_t mlfq_q[MLFQ_LEVELS];
static pcb_t  *mlfq_expired;      /* demoted in the last tick, still on the CPU */
static tick_t  mlfq_boosted;      /* last tick a boost was done */

static int mlfq_quantum(const pcb_t *p) { return cfg.quantum << p->level; }

/* Is a process ready at level `level` or higher (a smaller number)? */
static bool mlfq_ready_at(int level)
{
    for (int l = 0; l <= level; l++)
        if (!q_empty(&mlfq_q[l])) return true;
    return false;
}

/* No hook runs every tick, but every tick calls should_preempt (CPU busy)
 * or pick (CPU free), so both start with this. It boosts once per tick. */
static void mlfq_boost(void)
{
    if (now == 0 || now % MLFQ_BOOST != 0 || mlfq_boosted == now) return;
    mlfq_boosted = now;
    for (int l = 1; l < MLFQ_LEVELS; l++)          /* keep their order */
        while (!q_empty(&mlfq_q[l])) q_push(&mlfq_q[0], q_pop(&mlfq_q[l]));
    for (int i = 0; i < nprocs; i++)               /* also blocked and running */
        if (procs[i].state != P_TERMINATED) procs[i].level = 0;
    if (running) running->quantum_used = 0;
    mlfq_expired = NULL;
    trace("MLFQ boost: every process back to level 0");
}

static void mlfq_init(void)
{
    for (int l = 0; l < MLFQ_LEVELS; l++) q_init(&mlfq_q[l]);
    mlfq_expired = NULL;
    mlfq_boosted = -1;
}

static void mlfq_enqueue(pcb_t *p) { q_push(&mlfq_q[p->level], p); }

static pcb_t *mlfq_pick(void)
{
    mlfq_boost();
    for (int l = 0; l < MLFQ_LEVELS; l++)
        if (!q_empty(&mlfq_q[l])) return q_pop(&mlfq_q[l]);
    return NULL;
}

static void mlfq_on_dispatch(pcb_t *p) { p->quantum_used = 0; mlfq_expired = NULL; }

static void mlfq_on_tick(pcb_t *r)
{
    if (++r->quantum_used < mlfq_quantum(r)) return;
    if (r->level < MLFQ_LEVELS - 1) r->level++;
    r->quantum_used = 0;
    mlfq_expired = r;
    trace("MLFQ P%d used its quantum, now level %d", r->pid, r->level);
}

/* After its quantum, r gives way to anyone at its new level or higher; if
 * nobody is there it keeps the CPU with a new quantum, as in RR. Before
 * that, only a process at a higher level can take the CPU. */
static bool mlfq_should_preempt(pcb_t *r)
{
    mlfq_boost();
    if (r == mlfq_expired) {
        mlfq_expired = NULL;
        return mlfq_ready_at(r->level);
    }
    return r->level > 0 && mlfq_ready_at(r->level - 1);
}

static int mlfq_ready_count(void)
{
    int n = 0;
    for (int l = 0; l < MLFQ_LEVELS; l++) n += q_size(&mlfq_q[l]);
    return n;
}

static scheduler_t sched_mlfq = {
    "mlfq", mlfq_init, mlfq_enqueue, mlfq_should_preempt, mlfq_pick,
    mlfq_on_dispatch, mlfq_on_tick, mlfq_ready_count
};

static scheduler_t *all[] = {
    &sched_fcfs, &sched_rr, &sched_sjf, &sched_srtf, &sched_prio, &sched_mlfq
};

void sched_select(const char *name)
{
    for (size_t i = 0; i < sizeof(all) / sizeof(all[0]); i++) {
        if (strcmp(all[i]->name, name) == 0) {
            sched = all[i];
            sched->init();
            return;
        }
    }
    die("unknown scheduler '%s' (fcfs, rr, sjf, srtf, prio, mlfq)", name);
}
