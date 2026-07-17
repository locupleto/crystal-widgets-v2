/*
 * crystal_sampler — minimal system-metrics sampler for the crystal
 * Übersicht widgets.
 *
 * Replaces the crystal-htop fork: samples per-core CPU utilisation, load
 * averages, memory, swap, and task/thread counts once per interval and
 * publishes them twice:
 *
 *   1. metrics.json          — one atomically-renamed JSON snapshot with a
 *                              timestamp, so consumers can detect staleness.
 *   2. htop_*.txt            — the legacy crystal-htop file layout, so the
 *                              existing widgets work unchanged.
 *
 * All files are written to $HTOP_TEMP_DIR (default /tmp) via write-to-temp +
 * rename(), which is atomic on APFS: readers never see a torn file.
 *
 * Build:   make            (universal arm64 + x86_64 binary)
 * Run:     HTOP_TEMP_DIR=/path crystal_sampler [interval_seconds]
 *
 * A lock file guarantees a single instance per output directory.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <time.h>
#include <sys/sysctl.h>
#include <sys/file.h>
#include <sys/utsname.h>
#include <mach/mach.h>
#include <mach/mach_host.h>
#include <mach/processor_info.h>

#define MAX_CPUS 256

static const char *out_dir;

/* ---------- atomic file publishing ---------------------------------- */

static void publish(const char *name, const char *content)
{
    char tmp[1024], final[1024];
    snprintf(tmp, sizeof tmp, "%s/.%s.tmp", out_dir, name);
    snprintf(final, sizeof final, "%s/%s", out_dir, name);
    FILE *f = fopen(tmp, "w");
    if (!f)
        return;
    fputs(content, f);
    fclose(f);
    rename(tmp, final);
}

static void publishf(const char *name, const char *fmt, ...)
{
    char buf[512];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(buf, sizeof buf, fmt, ap);
    va_end(ap);
    publish(name, buf);
}

/* htop-style human size from KiB: "0K", "512M", "64.0G" */
static void human_kib(double kib, char *out, size_t n)
{
    if (kib >= 1024.0 * 1024.0)
        snprintf(out, n, "%.1fG", kib / (1024.0 * 1024.0));
    else if (kib >= 1024.0)
        snprintf(out, n, "%.0fM", kib / 1024.0);
    else
        snprintf(out, n, "%.0fK", kib);
}

/* ---------- samplers ------------------------------------------------- */

typedef struct {
    unsigned ncpu;
    double per_core[MAX_CPUS];      /* percent busy */
} cpu_sample_t;

static natural_t prev_ticks[MAX_CPUS][CPU_STATE_MAX];
static int have_prev = 0;

static void sample_cpu(cpu_sample_t *s)
{
    natural_t ncpu = 0;
    processor_info_array_t info;
    mach_msg_type_number_t count;

    s->ncpu = 0;
    if (host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO,
                            &ncpu, &info, &count) != KERN_SUCCESS)
        return;

    processor_cpu_load_info_t load = (processor_cpu_load_info_t)info;
    if (ncpu > MAX_CPUS)
        ncpu = MAX_CPUS;
    s->ncpu = ncpu;

    for (natural_t i = 0; i < ncpu; i++) {
        natural_t busy = 0, total = 0;
        for (int st = 0; st < CPU_STATE_MAX; st++) {
            natural_t d = load[i].cpu_ticks[st] - (have_prev ? prev_ticks[i][st] : 0);
            total += d;
            if (st != CPU_STATE_IDLE)
                busy += d;
            prev_ticks[i][st] = load[i].cpu_ticks[st];
        }
        s->per_core[i] = (have_prev && total > 0) ? 100.0 * busy / total : 0.0;
    }
    have_prev = 1;

    vm_deallocate(mach_task_self(), (vm_address_t)info,
                  count * sizeof(natural_t));
}

typedef struct {
    double total_kib, used_kib;             /* memory  */
    double swap_total_kib, swap_used_kib;   /* swap    */
} mem_sample_t;

static void sample_mem(mem_sample_t *m)
{
    memset(m, 0, sizeof *m);

    uint64_t memsize = 0;
    size_t len = sizeof memsize;
    sysctlbyname("hw.memsize", &memsize, &len, NULL, 0);
    m->total_kib = memsize / 1024.0;

    vm_size_t pagesize = 0;
    host_page_size(mach_host_self(), &pagesize);

    vm_statistics64_data_t vm;
    mach_msg_type_number_t count = HOST_VM_INFO64_COUNT;
    if (host_statistics64(mach_host_self(), HOST_VM_INFO64,
                          (host_info64_t)&vm, &count) == KERN_SUCCESS) {
        /* "used" = active + wired + compressed, htop/Activity-Monitor-like */
        uint64_t used_pages = (uint64_t)vm.active_count + vm.wire_count +
                              vm.compressor_page_count;
        m->used_kib = used_pages * (double)pagesize / 1024.0;
    }

    struct xsw_usage xsu;
    len = sizeof xsu;
    if (sysctlbyname("vm.swapusage", &xsu, &len, NULL, 0) == 0) {
        m->swap_total_kib = xsu.xsu_total / 1024.0;
        m->swap_used_kib = xsu.xsu_used / 1024.0;
    }
}

static void sample_tasks(int *tasks, int *threads)
{
    *tasks = 0;
    *threads = 0;
    processor_set_name_t pset;
    if (processor_set_default(mach_host_self(), &pset) != KERN_SUCCESS)
        return;
    struct processor_set_load_info li;
    mach_msg_type_number_t count = PROCESSOR_SET_LOAD_INFO_COUNT;
    if (processor_set_statistics(pset, PROCESSOR_SET_LOAD_INFO,
                                 (processor_set_info_t)&li,
                                 &count) == KERN_SUCCESS) {
        *tasks = li.task_count;
        *threads = li.thread_count;
    }
}

/* ---------- one-time static info ------------------------------------- */

static void publish_static_info(void)
{
    int ncpu = 0;
    size_t len = sizeof ncpu;
    sysctlbyname("hw.ncpu", &ncpu, &len, NULL, 0);
    publishf("htop_num_cpus.txt", "%d\n", ncpu);

    char brand[256] = "unknown";
    len = sizeof brand;
    sysctlbyname("machdep.cpu.brand_string", brand, &len, NULL, 0);
    publishf("htop_htop_cpu_brand.txt", "%s\n", brand);

    struct utsname u;
    if (uname(&u) == 0)
        publishf("htop_kernel_version.txt", "%s %s %s %s %s\n",
                 u.sysname, u.nodename, u.release, u.version, u.machine);
}

/* ---------- main loop ------------------------------------------------ */

int main(int argc, char **argv)
{
    const char *env = getenv("HTOP_TEMP_DIR");
    out_dir = (env && *env) ? env : "/tmp";

    double interval = (argc > 1) ? atof(argv[1]) : 1.0;
    if (interval < 0.2)
        interval = 1.0;

    /* single instance per output directory */
    char lockpath[1024];
    snprintf(lockpath, sizeof lockpath, "%s/crystal_sampler.lock", out_dir);
    int lockfd = open(lockpath, O_CREAT | O_RDWR, 0644);
    if (lockfd < 0 || flock(lockfd, LOCK_EX | LOCK_NB) != 0) {
        /* Another instance owns this directory — that is a healthy state.
         * Exit 0 so a launchd KeepAlive/SuccessfulExit=false agent does not
         * keep respawning us against the lock. */
        fprintf(stderr, "crystal_sampler: already running for %s\n", out_dir);
        return 0;
    }

    publish_static_info();

    cpu_sample_t cpu;
    mem_sample_t mem;
    char json[16384];

    /* prime the tick counters so the first published sample is a real delta */
    sample_cpu(&cpu);
    usleep((useconds_t)(interval * 1e6));

    for (;;) {
        sample_cpu(&cpu);
        sample_mem(&mem);

        int tasks, threads;
        sample_tasks(&tasks, &threads);

        double loads[3] = { 0, 0, 0 };
        getloadavg(loads, 3);

        /* ---- legacy crystal-htop files ---- */
        for (unsigned i = 0; i < cpu.ncpu; i++) {
            char name[64];
            snprintf(name, sizeof name, "htop_cpu_%03u.txt", i + 1);
            publishf(name, "%.1f\n", cpu.per_core[i]);
        }
        publishf("htop_load_avg_1.txt", "%.2f\n", loads[0]);
        publishf("htop_load_avg_2.txt", "%.2f\n", loads[1]);
        publishf("htop_load_avg_3.txt", "%.2f\n", loads[2]);

        char h_total[32], h_used[32], h_stotal[32], h_sused[32];
        human_kib(mem.total_kib, h_total, sizeof h_total);
        human_kib(mem.used_kib, h_used, sizeof h_used);
        human_kib(mem.swap_total_kib, h_stotal, sizeof h_stotal);
        human_kib(mem.swap_used_kib, h_sused, sizeof h_sused);

        publishf("htop_mem_avail.txt", "%f %s\n", mem.total_kib, h_total);
        publishf("htop_mem_used.txt", "%f %s\n", mem.used_kib, h_used);
        publishf("htop_swap_total.txt", "%f %s\n", mem.swap_total_kib, h_stotal);
        publishf("htop_swap_used.txt", "%f %s\n", mem.swap_used_kib, h_sused);
        publishf("htop_total_tasks.txt", "%d\n", tasks);
        publishf("htop_threads.txt", "%d\n", threads);

        /* ---- single atomic JSON snapshot ---- */
        time_t now = time(NULL);
        char iso[32];
        strftime(iso, sizeof iso, "%Y-%m-%dT%H:%M:%S%z", localtime(&now));

        int off = snprintf(json, sizeof json,
            "{\n"
            "  \"timestamp\": %ld,\n"
            "  \"time\": \"%s\",\n"
            "  \"interval\": %.1f,\n"
            "  \"load\": [%.2f, %.2f, %.2f],\n"
            "  \"tasks\": %d,\n"
            "  \"threads\": %d,\n"
            "  \"mem\": {\"total_kib\": %.0f, \"used_kib\": %.0f},\n"
            "  \"swap\": {\"total_kib\": %.0f, \"used_kib\": %.0f},\n"
            "  \"cpu\": [",
            (long)now, iso, interval, loads[0], loads[1], loads[2],
            tasks, threads, mem.total_kib, mem.used_kib,
            mem.swap_total_kib, mem.swap_used_kib);
        for (unsigned i = 0; i < cpu.ncpu && off < (int)sizeof json - 32; i++)
            off += snprintf(json + off, sizeof json - off, "%s%.1f",
                            i ? ", " : "", cpu.per_core[i]);
        snprintf(json + off, sizeof json - off, "]\n}\n");
        publish("metrics.json", json);

        usleep((useconds_t)(interval * 1e6));
    }
}
