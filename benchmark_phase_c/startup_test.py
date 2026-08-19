import subprocess
import time
import os
import statistics

BASE = os.path.dirname(os.path.abspath(__file__))
RUNS = 15


def time_runs(cmd):
    times = []
    for _ in range(RUNS):
        t0 = time.perf_counter()
        subprocess.run(cmd, capture_output=True, cwd=BASE)
        t1 = time.perf_counter()
        times.append(t1 - t0)
    times.sort()
    return statistics.median(times), min(times)


tvk_med, tvk_min = time_runs([os.path.join(BASE, 'hello_tkv.exe')])
cs_med, cs_min = time_runs([os.path.join(BASE, 'hello_cs.exe')])
py_med, py_min = time_runs(['py', os.path.join(BASE, 'hello.py')])

print(f"{'':16}{'median(s)':>12}{'min(s)':>12}")
print(f"{'TokenVector':16}{tvk_med:>12.4f}{tvk_min:>12.4f}")
print(f"{'C#':16}{cs_med:>12.4f}{cs_min:>12.4f}")
print(f"{'Python3':16}{py_med:>12.4f}{py_min:>12.4f}")
