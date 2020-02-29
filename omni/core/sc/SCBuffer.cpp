#include <cstdio>
#include "SC_Utilities/SC_World.h"
#include "SC_Utilities/SC_Unit.h"

extern "C"
{
    //Called at start of perform (scsynth)
    void* get_buffer_SC(void* buffer_SCWorld, float fbufnum)
    {
        if(!buffer_SCWorld)
            return nullptr;

        World* SCWorld = (World*)buffer_SCWorld;

        uint32 bufnum = (int)fbufnum; 

        //If bufnum is not more that maximum number of buffers in World* it means bufnum doesn't point to a LocalBuf
        if(!(bufnum >= SCWorld->mNumSndBufs))
        {
            SndBuf* buf = SCWorld->mSndBufs + bufnum; 

            if(!buf->data)
            {
                printf("WARNING: Omni: Invalid buffer: %d\n", bufnum);
                return nullptr;
            }

            #ifdef SUPERNOVA
                //It should be another custom function, work it out when doing supernova support.

                /* This locking should not be here, as this happens only when retrieving a new buffer, not at every sample loop.
                Another function should be called from omni side to do the locking accordingly. */

                //printf("Lock supernova\n");
                //LOCK_SNDBUF_SHARED(buf);
            #endif

            return (void*)buf;
        }
        else
        {
            printf("WARNING: Omni: local buffers are not yet supported \n");
            return nullptr;
        
            /* int localBufNum = bufnum - SCWorld->mNumSndBufs; 
            
            Graph *parent = unit->mParent; 
            
            if(localBufNum <= parent->localBufNum)
                unit->m_buf = parent->mLocalSndBufs + localBufNum; 
            else 
            { 
                bufnum = 0; 
                unit->m_buf = SCWorld->mSndBufs + bufnum; 
            } 

            return (void*)buf;
            */
        }
    }

    #ifdef SUPERNOVA
    void unlock_buffer_SC(void* buf)
    {
        /* UNLOCK THE BUFFER HERE... To be called at the end of perform macro (supernova) */

        //printf("SUPERNOVA BUFFER!!!\n");

        return;
    }
    #endif

    float get_float_value_buffer_SC(void* buf, long index, long channel)
    {
        if(buf)
        {
            SndBuf* snd_buf = (SndBuf*)buf;

            //Supernova should lock here
                    
            long actual_index = (index * snd_buf->channels) + channel; //Interleaved data
            
            if(index >= 0 && (actual_index < snd_buf->samples))
                return snd_buf->data[actual_index];
        }
        
        return 0.f;
    }

    void set_float_value_buffer_SC(void* buf, float value, long index, long channel)
    {
        if(buf)
        {
            SndBuf* snd_buf = (SndBuf*)buf;
            
            //Supernova should lock here
            
            long actual_index = (index * snd_buf->channels) + channel; //Interleaved data
            
            if(index >= 0 && (actual_index < snd_buf->samples))
            {
                snd_buf->data[actual_index] = value;
                return;
            }
        }
    }

    //Length of each channel
    int get_frames_buffer_SC(void* buf)
    {
        if(buf)
        {
            SndBuf* snd_buf = (SndBuf*)buf;
            return snd_buf->frames;
        }
            
        return 0;
    }

    //Total allocated length
    int get_samples_buffer_SC(void* buf)
    {
        if(buf)
        {
            SndBuf* snd_buf = (SndBuf*)buf;
            return snd_buf->samples;
        }

        return 0;
    }

    //Number of channels
    int get_channels_buffer_SC(void* buf)
    {
        if(buf)
        {
            SndBuf* snd_buf = (SndBuf*)buf;
            return snd_buf->channels;
        }
            
        return 0;
    }

    //Samplerate
    double get_samplerate_buffer_SC(void* buf)
    {
        if(buf)
        {
            SndBuf* snd_buf = (SndBuf*)buf;
            return snd_buf->samplerate;
        }
            
        return 0;
    }

    //Sampledur
    double get_sampledur_buffer_SC(void* buf)
    {
        if(buf)
        {
            SndBuf* snd_buf = (SndBuf*)buf;
            return snd_buf->sampledur;
        }
            
        return 0;
    }
}