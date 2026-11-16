//! Linux: a per-thread CPU-time POSIX timer signals SIGPROF to its own thread.

use std::io;
use std::sync::OnceLock;

// A wrapper around pthread_t that is Send + Sync.
// On musl, pthread_t = *mut c_void which is not Send/Sync by default.
// Since we only use it for timer_create (which takes it by value) and
// pthread_self() returns the calling thread's own ID, it's safe to share.
#[derive(Clone, Copy, Default)]
struct PthreadT(libc::pthread_t);
unsafe impl Send for PthreadT {}
unsafe impl Sync for PthreadT {}

#[derive(Default)]
pub struct Target {
    tid: libc::c_int,
    pthread: PthreadT,
}

pub struct Timer(libc::timer_t);

// SAFETY: a timer id is a kernel handle, usable and deletable from any thread.
unsafe impl Send for Timer {}

impl Target {
    pub fn current() -> Option<Self> {
        // SAFETY: gettid takes no arguments; pthread_self is always valid for the calling thread.
        let (tid, pthread) = unsafe {
            (
                libc::syscall(libc::SYS_gettid) as libc::c_int,
                libc::pthread_self(),
            )
        };
        Some(Self {
            tid,
            pthread: PthreadT(pthread),
        })
    }
}

pub fn arm(target: &Target, hz: u32) -> io::Result<Timer> {
    arm_clock(target, hz, None)
}

/// A timer on the monotonic clock, signalling SIGRTMIN: it queues, so it never merges with a CPU-time SIGPROF.
pub fn arm_wall(target: &Target, hz: u32) -> io::Result<Timer> {
    arm_clock(target, hz, Some(libc::CLOCK_MONOTONIC))
}

fn arm_clock(target: &Target, hz: u32, wall: Option<libc::clockid_t>) -> io::Result<Timer> {
    let period = 1_000_000_000 / u64::from(hz.max(1));
    let tick = libc::timespec {
        tv_sec: (period / 1_000_000_000) as _,
        tv_nsec: (period % 1_000_000_000) as _,
    };
    // SAFETY: all-zero is a valid sigevent/itimerspec; the out-pointers are live locals; the registry lock keeps the pthread alive.
    unsafe {
        let mut clock = wall.unwrap_or(0);
        if wall.is_none() {
            // Extract inner pthread_t from PthreadT wrapper
            let rc = libc::pthread_getcpuclockid(target.pthread.0, &mut clock);
            if rc != 0 {
                return Err(io::Error::from_raw_os_error(rc));
            }
        }
        let mut event: libc::sigevent = std::mem::zeroed();
        // SIGEV_THREAD_ID is not available on musl; use SIGEV_THREAD instead.
        // The thread ID is passed via sigev_value.sival_ptr per POSIX.
        event.sigev_notify = libc::SIGEV_THREAD;
        event.sigev_signo = if wall.is_some() {
            libc::SIGRTMIN()
        } else {
            libc::SIGPROF
        };
        // For SIGEV_THREAD, the thread ID goes in sigev_value.sival_ptr
        event.sigev_value.sival_ptr = target.tid as *mut libc::c_void;
        let mut id = std::ptr::null_mut();
        if libc::timer_create(clock, &mut event, &mut id) != 0 {
            return Err(io::Error::last_os_error());
        }
        let spec = libc::itimerspec {
            it_interval: tick,
            it_value: tick,
        };
        if libc::timer_settime(id, 0, &spec, std::ptr::null_mut()) != 0 {
            let e = io::Error::last_os_error();
            libc::timer_delete(id);
            return Err(e);
        }
        Ok(Timer(id))
    }
}

pub fn disarm(timer: Timer) {
    // SAFETY: the id came from timer_create and is deleted once (the caller took it out of its slot).
    unsafe { libc::timer_delete(timer.0) };
}

/// The calling thread's CPU clock; clock_gettime is async-signal-safe.
pub fn thread_cpu_ns() -> u64 {
    let mut ts = libc::timespec {
        tv_sec: 0,
        tv_nsec: 0,
    };
    // SAFETY: ts is a live out-pointer.
    unsafe { libc::clock_gettime(libc::CLOCK_THREAD_CPUTIME_ID, &mut ts) };
    ts.tv_sec as u64 * 1_000_000_000 + ts.tv_nsec as u64
}

#[cfg(target_arch = "x86_64")]
fn registers(uc: &libc::ucontext_t) -> super::Regs {
    let g = &uc.uc_mcontext.gregs;
    super::Regs {
        pc: g[libc::REG_RIP as usize] as usize,
        fp: g[libc::REG_RBP as usize] as usize,
        sp: g[libc::REG_RSP as usize] as usize,
        lr: 0,
    }
}

#[cfg(target_arch = "aarch64")]
fn registers(uc: &libc::ucontext_t) -> super::Regs {
    let m = &uc.uc_mcontext;
    super::Regs {
        pc: m.pc as usize,
        fp: m.regs[29] as usize,
        sp: m.sp as usize,
        lr: m.regs[30] as usize,
    }
}

#[cfg(any(target_arch = "x86_64", target_arch = "aarch64"))]
extern "C" fn handler(signal: libc::c_int, _: *mut libc::siginfo_t, uc: *mut libc::c_void) {
    // SAFETY: errno is thread-local; saving it keeps the interrupted code's value (async-signal-safe practice).
    let errno = unsafe { *libc::__errno_location() };
    // SAFETY: the kernel passes a valid ucontext_t to an SA_SIGINFO handler.
    let regs = registers(unsafe { &*(uc as *const libc::ucontext_t) });
    super::on_sample(regs, signal != libc::SIGPROF);
    // SAFETY: restores the value saved above.
    unsafe { *libc::__errno_location() = errno };
}

/// Installs SIGPROF's handler once and leaves it (inert when nothing is armed): a signal queued before a stop must not kill the process.
#[cfg(any(target_arch = "x86_64", target_arch = "aarch64"))]
pub fn install_handler() -> io::Result<()> {
    static INSTALLED: OnceLock<Result<(), i32>> = OnceLock::new();
    let result = INSTALLED.get_or_init(|| {
        // SAFETY: a zeroed sigaction is filled in before use; the handler touches only thread-locals, atomics and the ring.
        unsafe {
            let mut action: libc::sigaction = std::mem::zeroed();
            action.sa_sigaction = handler as *const () as usize;
            action.sa_flags = libc::SA_SIGINFO | libc::SA_RESTART;
            libc::sigemptyset(&mut action.sa_mask);
            // Each handler blocks the other signal, so the two never nest on one ring.
            libc::sigaddset(&mut action.sa_mask, libc::SIGPROF);
            libc::sigaddset(&mut action.sa_mask, libc::SIGRTMIN());
            for signal in [libc::SIGPROF, libc::SIGRTMIN()] {
                if libc::sigaction(signal, &action, std::ptr::null_mut()) != 0 {
                    return Err(io::Error::last_os_error()
                        .raw_os_error()
                        .unwrap_or(libc::EINVAL));
                }
            }
            Ok(())
        }
    });
    result.map_err(io::Error::from_raw_os_error)
}

#[cfg(not(any(target_arch = "x86_64", target_arch = "aarch64")))]
pub fn install_handler() -> io::Result<()> {
    Err(io::ErrorKind::Unsupported.into())
}
