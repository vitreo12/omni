#include <atomic>

#pragma once

/* Spinlock and Trylock classes */

class AtomicBarrier
{
    public:
        AtomicBarrier()
        {
            barrier.store(false);
        }

        ~AtomicBarrier(){}

        void Spinlock();

        bool Trylock();

        void Unlock();

        bool get_barrier_value();

    private:
        std::atomic<bool> barrier{false}; //Should it be atomic_flag instead? Would it be faster?
};

class OmniAtomicBarrier : public AtomicBarrier
{
    public:
        OmniAtomicBarrier(){}
        ~OmniAtomicBarrier(){}

        void NRTSpinlock();

        /* Used in RT thread. Returns true if compare_exchange_strong succesfully exchange the value. False otherwise. */
        bool RTTrylock();
};

/******************/
/* Struct version */
/******************/

typedef struct AtomicBarrier_struct
{
    std::atomic<bool> state{false};
} AtomicBarrier_t;

void spinlock(AtomicBarrier_t* barrier)
{
    bool expected_val = false;
    while(!barrier->state.compare_exchange_weak(expected_val, true))
        expected_val = false; //reset expected_val to false as it's been changed in compare_exchange_weak to true
}

void unlock(AtomicBarrier_t* barrier)
{
    barrier->state.store(false);
}

bool trylock(AtomicBarrier_t* barrier)
{
    bool expected_val = false;
    return barrier->state.compare_exchange_strong(expected_val, true);
}