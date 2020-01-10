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