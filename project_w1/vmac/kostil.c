#include <linux/export.h>
#include <linux/mmc/host.h>
#include <linux/mmc/sdio.h>
#include <linux/sched.h>
#include <linux/sched/task.h>

const char *get_wifi_inf(void);
void sdio_reinit(void);

const char *get_wifi_inf(void)
{
    return "sdio";
}
EXPORT_SYMBOL(get_wifi_inf);

// Временная заглушка
void sdio_reinit(void)
{
    pr_debug("[%s] stub called\n", __func__);
}
EXPORT_SYMBOL(sdio_reinit);

int sched_setscheduler(struct task_struct *p, int policy,
                       const struct sched_param *param)
{
    struct sched_param sparam = { .sched_priority = 0 };
    
    if (!p || !param)
        return -EINVAL;
    
    p->policy = policy;
    p->prio = sparam.sched_priority;
    
    return 0;
}
EXPORT_SYMBOL(sched_setscheduler);
