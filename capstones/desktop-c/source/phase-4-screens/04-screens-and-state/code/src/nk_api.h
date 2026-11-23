#ifndef TS_NK_API_H
#define TS_NK_API_H

/* One place that configures Nuklear. Every file that uses Nuklear includes this header,
   and only nk_impl.c defines NK_IMPLEMENTATION before including it. */
#include <SDL3/SDL.h>

#define NK_INCLUDE_FIXED_TYPES
#define NK_INCLUDE_STANDARD_BOOL
#define NK_INCLUDE_STANDARD_VARARGS
#define NK_INCLUDE_FONT_BAKING
#define NK_INCLUDE_DEFAULT_FONT
#define NK_INCLUDE_COMMAND_USERDATA
#define NK_INCLUDE_VERTEX_BUFFER_OUTPUT

#include "nuklear.h"
#include "nuklear_sdl3_renderer.h"

#endif
