/* tkv_platform.h — Win32 -> POSIX shim for Linux build (Colab/WSL).
 * The .tkv engine's hot kernels are untouched; only OS API surface is shimmed.
 * Include this header INSTEAD of <windows.h> when _WIN32 is not defined. */
#ifndef TKV_PLATFORM_H
#define TKV_PLATFORM_H

#ifdef _WIN32
#include <windows.h>
#else
#define _GNU_SOURCE
#include <dlfcn.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <linux/limits.h>

/* ---- basic types ------------------------------------------------- */
typedef uint32_t DWORD;
typedef int BOOL;
typedef void* HANDLE;
typedef void* LPVOID;
typedef void* HMODULE;
typedef uintptr_t INT_PTR;
typedef uintptr_t UINT_PTR;
typedef uintptr_t DWORD_PTR;
typedef long LONG;           /* size matches Win32 LONG on x86_64 LP64 */
typedef void* (*LPTHREAD_START_ROUTINE)(void*);
#define TRUE 1
#define FALSE 0
#define INFINITE 0xFFFFFFFFu
#define MAX_PATH PATH_MAX
#define WINAPI
#define CALLBACK
#define WIN32_LEAN_AND_MEAN

/* ---- SRW lock / INIT_ONCE ---------------------------------------- */
typedef pthread_mutex_t SRWLOCK;
#define SRWLOCK_INIT PTHREAD_MUTEX_INITIALIZER
typedef pthread_once_t INIT_ONCE;
#define INIT_ONCE_STATIC_INIT PTHREAD_ONCE_INIT
static inline void AcquireSRWLockExclusive(SRWLOCK* l) { pthread_mutex_lock(l); }
static inline void ReleaseSRWLockExclusive(SRWLOCK* l) { pthread_mutex_unlock(l); }

/* ---- environment / paths ----------------------------------------- */
static inline DWORD GetActiveProcessorCount(DWORD_PTR grp) { (void)grp; return (DWORD)sysconf(_SC_NPROCESSORS_ONLN); }
#define ALL_PROCESSOR_GROUPS 0xFFFFu
static inline DWORD GetEnvironmentVariableA(const char* name, char* buf, DWORD size) {
    const char* v = getenv(name);
    if (!v) return 0;
    strncpy(buf, v, size); buf[size - 1] = 0;
    return (DWORD)strlen(buf);
}
static inline DWORD GetModuleFileNameA(HMODULE mod, char* buf, DWORD size) {
    (void)mod;
    ssize_t n = readlink("/proc/self/exe", buf, size);
    if (n <= 0) { buf[0] = 0; return 0; }
    buf[n] = 0; return (DWORD)n;
}
static inline BOOL LoadLibraryA_IsOK(void) { return 1; }
#define LoadLibraryA(p)            ((HMODULE)dlopen((p), RTLD_LAZY | RTLD_LOCAL))
#define LoadLibraryExA(p, h, f)    ((HMODULE)dlopen((p), RTLD_LAZY | RTLD_LOCAL))
#define FreeLibrary(h)             ((void)dlclose((h)))
#define GetProcAddress(h, name)    ((void*)dlsym((h), (name)))

/* ---- events as semaphores (reused per-job, one post each) --------- */
static inline HANDLE CreateEventA(void* attr, BOOL manual, BOOL initial, const char* name) {
    (void)attr; (void)manual; (void)name;
    sem_t* s = (sem_t*)calloc(1, sizeof(sem_t));
    if (!s) return NULL;
    sem_init(s, 0, initial ? 1 : 0);
    return (HANDLE)s;
}
static inline BOOL SetEvent(HANDLE h) { if (h) sem_post((sem_t*)h); return TRUE; }
static inline BOOL ResetEvent(HANDLE h) { if (h) { int v; (void)sem_getvalue((sem_t*)h, &v); while (v > 0) { sem_wait((sem_t*)h); v--; } } return TRUE; }
static inline DWORD WaitForSingleObject(HANDLE h, DWORD ms) {
    (void)ms;
    while (sem_wait((sem_t*)h) != 0) { /* retry */ }
    return 0;
}
static inline DWORD WaitForMultipleObjects(DWORD count, const HANDLE* arr, BOOL wait_all, DWORD ms) {
    (void)wait_all; (void)ms;
    for (DWORD i = 0; i < count; i++) { while (sem_wait((sem_t*)arr[i]) != 0) { } }
    return 0;
}
static inline BOOL CloseHandle(HANDLE h) {
    if (h) { sem_destroy((sem_t*)h); free(h); }
    return TRUE;
}

/* ---- one-shot thread: returns a "done" sem_t* the caller can wait -- */
typedef struct { sem_t done; void (*fn)(void*); void* arg; } tkv_thread_ctx;
static void* tkv_thread_wrap(void* p) {
    tkv_thread_ctx* c = (tkv_thread_ctx*)p;
    c->fn(c->arg);
    sem_post(&c->done);
    /* keep ctx alive: caller frees ctx+sem in CloseHandle */
    return NULL;
}
static inline HANDLE CreateThread(void* attr, size_t stack, void* fn, void* arg, DWORD flags, DWORD* id) {
    (void)attr; (void)stack; (void)flags; (void)id;
    tkv_thread_ctx* c = (tkv_thread_ctx*)calloc(1, sizeof(*c));
    if (!c) return NULL;
    sem_init(&c->done, 0, 0);
    c->fn = (void (*)(void*))fn;
    c->arg = arg;
    pthread_t tid;
    if (pthread_create(&tid, NULL, tkv_thread_wrap, c) != 0) {
        sem_destroy(&c->done); free(c); return NULL;
    }
    pthread_detach(tid);
    /* Callers treat the returned HANDLE via WaitForSingleObject/Multiple + CloseHandle,
     * which operate on sem_t* — wrap the ctx in a tiny indirection so both work. */
    return (HANDLE)c;  /* cast ok: same layout as sem_t stored first */
}
/* CreateEventA handles are raw sem_t*, thread handles are tkv_thread_ctx* whose
 * first member is the sem_t. All ops above only touch the leading sem_t. */

/* ---- interlocked ops ---------------------------------------------- */
#define InterlockedIncrement(p)          (__sync_fetch_and_add((LONG*)(p), 1) + 1)
#define InterlockedCompareExchange(p, x, c) __sync_val_compare_and_swap((LONG*)(p), (c), (x))

#endif /* !_WIN32 */
#endif /* TKV_PLATFORM_H */

/* pthread_once trampoline (Win32 passes an INIT_ONCE callback with args;
/* pthread_once wants a void(*)(void) — tkv code calls InitOnceExecuteOnce(&g_once, tkv_pool_init, NULL, NULL)). */
#define InitOnceExecuteOnce(once, cb, p1, p2) pthread_once((once), (void (*)(void))(cb))
