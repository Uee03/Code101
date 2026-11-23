#include <cjson/cJSON.h>
#include <stdio.h>
#include <stdlib.h>

#include "log.h"
#include "nk_api.h"
#include "store.h"
#include "ui.h"
#include "util.h"

#define WINDOW_WIDTH 1100
#define WINDOW_HEIGHT 720

int main(int argc, char **argv) {
    (void)argc;
    (void)argv;

    int exit_code = EXIT_FAILURE;
    SDL_Window *window = NULL;
    SDL_Renderer *renderer = NULL;
    struct nk_context *nk = NULL;
    ts_store store;
    bool store_ready = false;
    float scale = 1.0f;

    ts_log_init();
    /* cJSON allocates through our counted functions too, so the leak report below covers it.
       This must run before the first cJSON call and must never change afterwards. */
    cJSON_Hooks hooks = {ts_malloc, ts_free};
    cJSON_InitHooks(&hooks);

    if (!SDL_Init(SDL_INIT_VIDEO)) {
        fprintf(stderr, "SDL_Init failed: %s\n", SDL_GetError());
        return EXIT_FAILURE;
    }
    if (!SDL_CreateWindowAndRenderer("Tasks and Teams", WINDOW_WIDTH, WINDOW_HEIGHT, SDL_WINDOW_RESIZABLE,
                                     &window, &renderer)) {
        fprintf(stderr, "Window creation failed: %s\n", SDL_GetError());
        goto cleanup;
    }
    SDL_SetRenderVSync(renderer, 1);

    scale = SDL_GetWindowDisplayScale(window);
    if (scale < 1.0f) scale = 1.0f; /* 0 means "unknown" */
    SDL_SetRenderScale(renderer, scale, scale);

    nk = nk_sdl_init(window, renderer, nk_sdl_allocator());
    if (nk == NULL) {
        fprintf(stderr, "Nuklear initialisation failed\n");
        goto cleanup;
    }
    {
        /* Bake the built-in font at the physical size, then draw it at the logical size:
           the text stays sharp on high-DPI displays. */
        struct nk_font_config font_config = nk_font_config(0);
        struct nk_font_atlas *atlas = nk_sdl_font_stash_begin(nk);
        struct nk_font *font = nk_font_atlas_add_default(atlas, 16.0f * scale, &font_config);
        nk_sdl_font_stash_end(nk);
        if (font != NULL) {
            font->handle.height /= scale;
            nk_style_set_font(nk, &font->handle);
        }
    }

    if (!ts_store_init(&store)) {
        fprintf(stderr, "Could not start the application\n");
        goto cleanup;
    }
    store_ready = true;

    bool running = true;
    while (running) {
        SDL_Event event;
        nk_input_begin(nk);
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT) running = false;
            SDL_ConvertEventToRenderCoordinates(renderer, &event);
            nk_sdl_handle_event(nk, &event);
        }
        nk_input_end(nk);

        ts_store_pump(&store);

        int pixel_w = 0, pixel_h = 0;
        SDL_GetCurrentRenderOutputSize(renderer, &pixel_w, &pixel_h);
        ts_ui_frame(nk, &store, (float)pixel_w / scale, (float)pixel_h / scale);
        nk_sdl_update_TextInput(nk);

        SDL_SetRenderDrawColor(renderer, 24, 28, 36, 255);
        SDL_RenderClear(renderer);
        nk_sdl_render(nk, NK_ANTI_ALIASING_ON);
        SDL_RenderPresent(renderer);
    }
    exit_code = EXIT_SUCCESS;

cleanup:
    /* Reverse order of creation: the store (it stops the worker first), the UI, the window, SDL. */
    if (store_ready) ts_store_shutdown(&store);
    if (nk != NULL) nk_sdl_shutdown(nk);
    if (renderer != NULL) SDL_DestroyRenderer(renderer);
    if (window != NULL) SDL_DestroyWindow(window);
    SDL_Quit();

#ifndef NDEBUG
    {
        long outstanding = ts_alloc_outstanding();
        fprintf(stderr, "allocations outstanding: %ld\n", outstanding);
        if (outstanding != 0 && exit_code == EXIT_SUCCESS) exit_code = 2; /* a leak fails the run */
    }
#endif
    return exit_code;
}
