os_stats() {
  printf 'Memory usage: %s\n' $(cat /sys/fs/cgroup/memory/memory.usage_in_bytes | bytes2human)
  cat /sys/fs/cgroup/cpu.pressure
  printf 'Memory usage: %s\n' $(cat /sys/fs/cgroup/cpu/cpuacct.usage)
}
