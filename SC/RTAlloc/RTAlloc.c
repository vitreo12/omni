typedef unsigned long size_t; 

typedef struct World World;

//RT mem allocation function pointers
typedef void* RTAlloc_ptr(World *inWorld, size_t inSize);
RTAlloc_ptr* RTAlloc;

typedef void* RTRealloc_ptr(World *inWorld, void *inPtr, size_t inSize);
RTRealloc_ptr* RTRealloc;

typedef void  RTFree_ptr(World *inWorld, void *inPtr);
RTFree_ptr* RTFree;

//OR:
/*
void* (*RTAlloc)(World *inWorld, size_t inSize);
void* (*RTRealloc)(World *inWorld, void *inPtr, size_t inSize);
void  (*RTFree)(World *inWorld, void *inPtr);

void init_alloc_function_pointers(void* (*In_RTAlloc)(World *inWorld, size_t inSize), void* (*In_RTRealloc)(World *inWorld, void *inPtr, size_t inSize), void  (*In_RTFree)(World *inWorld, void *inPtr))
{
    printf("Calling init_alloc_function_pointers\n");
    RTAlloc   = In_RTAlloc;
    RTRealloc = In_RTRealloc;
    RTFree    = In_RTFree;
}
*/

//Global variable that will live in each Nim module that compiles this "RTAlloc.c" file
World* SCWorld;

//Called when loading a NimCollider module
void init_world(void* inWorld)
{
    printf("Calling init_world\n");
    SCWorld = (World*)inWorld;
}

void* get_sc_world()
{
    return (void*)SCWorld;
}

void print_world()
{
    printf("SCWorld: %p\n", (void*)SCWorld);
}

void init_alloc_function_pointers(RTAlloc_ptr* In_RTAlloc, RTRealloc_ptr* In_RTRealloc, RTFree_ptr* In_RTFree)
{
    printf("Calling init_alloc_function_pointers\n");
    RTAlloc   = In_RTAlloc;
    RTRealloc = In_RTRealloc;
    RTFree    = In_RTFree;
}

void* rt_alloc(size_t inSize)
{
    printf("Calling rt_alloc with size: %d\n", inSize);
    return RTAlloc(SCWorld, inSize);
}

void* rt_alloc0(size_t inSize)
{
    printf("Calling rt_alloc0 with size: %d\n", inSize);
    void* memory = RTAlloc(SCWorld, inSize);
    if(memory)
        memset(memory, 0, inSize);

    return memory;
}

void* rt_realloc(void* inPtr, size_t inSize) 
{
    printf("Calling rt_realloc\n");
    return RTRealloc(SCWorld, inPtr, inSize);
}

void rt_free(void* inPtr)
{
    printf("Calling rt_free\n");
    RTFree(SCWorld, inPtr);
}