"""
Práctica Semana 11 – Evaluación de Desempeño
CUCEI – Programación Paralela y Concurrente

Operación: Suma de raíces cuadradas (CPU-bound, N=5_000_000 elementos)
"""
import time
import math
from concurrent.futures import ThreadPoolExecutor

# ─── Parámetros ──────────────────────────────────────────────────────────────
N = 5_000_000
REPS = 3

DATA = list(range(1, N + 1))

# ─── Operación ───────────────────────────────────────────────────────────────
def sum_chunk(chunk):
    return sum(math.sqrt(x) for x in chunk)

def split_chunks(data, n_chunks):
    size = len(data) // n_chunks
    return [data[i*size:(i+1)*size] for i in range(n_chunks)]

# ─── Versión Secuencial ───────────────────────────────────────────────────────
def run_sequential():
    return sum_chunk(DATA)

# ─── Versión Paralela ─────────────────────────────────────────────────────────
def run_parallel(num_threads):
    chunks = split_chunks(DATA, num_threads)
    with ThreadPoolExecutor(max_workers=num_threads) as executor:
        partial_sums = list(executor.map(sum_chunk, chunks))
    return sum(partial_sums)

# ─── Medición ────────────────────────────────────────────────────────────────
def measure(fn, *args):
    times = []
    for _ in range(REPS):
        t0 = time.perf_counter()
        if args:
            fn(*args)
        else:
            fn()
        times.append(time.perf_counter() - t0)
    return sum(times) / len(times)

print(f"Benchmark: suma de sqrt(x) para N={N:,} elementos, {REPS} repeticiones\n")

t_seq = measure(run_sequential)
print(f"  Secuencial:   {t_seq:.4f} s")

thread_counts = [1, 2, 4]
results = {}

for t in thread_counts:
    t_par = measure(run_parallel, t)
    speedup = t_seq / t_par
    efficiency = speedup / t * 100
    results[t] = {"t_par": t_par, "speedup": speedup, "efficiency": efficiency}
    print(f"  {t} hilo(s):    {t_par:.4f} s | Speedup={speedup:.3f}x | Eficiencia={efficiency:.1f}%")

import json
data = {
    "t_seq": t_seq,
    "N": N,
    "REPS": REPS,
    "results": {str(k): v for k, v in results.items()}
}
with open("/home/claude/results.json", "w") as f:
    json.dump(data, f)

print("\nListo.")
