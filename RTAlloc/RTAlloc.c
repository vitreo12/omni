//clang has malloc builtin
#ifndef __clang__
    #include "malloc.h"
#endif

typedef unsigned long size_t; 

typedef struct World World;

//Global variable that will live in each Nim module that compiles this "RTAlloc.c" file
World* sc_world;

//Called when loading a NimCollider module
void init_world(void* in_world)
{
    sc_world = (World*)in_world;
}

void print_world()
{
    printf("%p\n", (void*)sc_world);
}

void* rt_alloc(size_t in_size)
{
	return malloc(in_size);
}

void* rt_alloc0(size_t in_size)
{
    void* memory = malloc(in_size);
    if(memory)
        memset(memory, 0, in_size);

    return memory;
}

void* rt_realloc(void* in_ptr, size_t in_size) 
{
    return realloc(in_ptr, in_size);
}

void rt_free(void* in_ptr)
{
    free(in_ptr);
}