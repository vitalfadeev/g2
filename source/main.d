import std.conv;
import std.format;
import std.stdio;
import bindbc.sdl;
import pic;


int 
main () {
    // Init
    init_sdl ();

    // Window, Surface
    SDL_Window*  window;
    new_window (window);

    // Renderer
    SDL_Renderer* renderer;
    new_renderer (window, renderer);

    // Event Loop
    event_loop (window, renderer, &frame);

    return 0;
}


//
void 
init_sdl () {
    SDLSupport ret = loadSDL();

    if (ret != sdlSupport) {
        if (ret == SDLSupport.noLibrary) 
            throw new Exception ("The SDL shared library failed to load");
        else 
        if (ret == SDLSupport.badLibrary) 
            throw new Exception ("One or more symbols failed to load. The likely cause is that the shared library is for a lower version than bindbc-sdl was configured to load (via SDL_204, GLFW_2010 etc.)");
    }

    loadSDL ("sdl2.dll");
}


//
void 
new_window (ref SDL_Window* window) {
    // Window
    window = 
        SDL_CreateWindow (
            "SDL2 Window",
            SDL_WINDOWPOS_CENTERED,
            SDL_WINDOWPOS_CENTERED,
            640, 480,
            0
        );

    if (!window)
        throw new SDLException ("Failed to create window");

    // Update
    SDL_UpdateWindowSurface (window);
}


//
void 
new_renderer (SDL_Window* window, ref SDL_Renderer* renderer) {
    renderer = SDL_CreateRenderer (window, -1, SDL_RENDERER_SOFTWARE);
}


//
void 
event_loop (ref SDL_Window* window, SDL_Renderer* renderer, void function(SDL_Renderer* renderer) frame) {
    //
    bool game_is_still_running = true;

    //
    while (game_is_still_running) {
        SDL_Event e;

        while (SDL_PollEvent (&e) > 0) {
            // Process Event
            // SDL_QUIT
            if (e.type == SDL_QUIT) {
                game_is_still_running = false;
                break;
            }

            // Render
            frame (renderer);

            // Rasterize
            SDL_RenderPresent (renderer);
        }

        // Delay
        SDL_Delay (100);
    }        
}


//
class 
SDLException : Exception {
    this (string msg) {
        super (format!"%s: %s" (SDL_GetError().to!string, msg));
    }
}


//
void
frame (SDL_Renderer* renderer) {
    // SDL_SetRenderDrawColor (renderer, 0xFF, 0xFF, 0xFF, 0xFF);
    // SDL_RenderDrawPoint (renderer, x, y);
    // ...

    // picture
    Pic pic_0;

    Pic pic_1;
    pic_1.els ~= Pic.El( Pic.El.Type.CLOSED_LINE, [
        XY(0,0), XY(100,0), XY(100,100), XY(0,100),
    ]);

    Pic pic_2;
    pic_2.els ~= Pic.El( Pic.El.Type.CLOSED_LINE, [
        XY(50,0), XY(100,50), XY(50,100), XY(50,0),
    ]);

    // pictures table
    Pics pics;
    pics ~= pic_0;  // 0: pic_0
    pics ~= pic_1;  // 1: pic_1
    pics ~= pic_2;  // 2: pic_2

    // 3 picture_ids flow
    IDS ids;
    ids ~= 1;
    ids ~= 1;
    ids ~= 2;

    // G
    PicG g;

    // Prepare render...
    auto window = SDL_RenderGetWindow (renderer);
    SDL_Rect rect;
    SDL_GetWindowSize (window, &rect.w, &rect.h);
    
    auto surface = SDL_GetWindowSurface (window);
    if (surface is null)
        throw new SDLException ("SDL_GetWindowSurface: ");

    if (SDL_RenderReadPixels (
            renderer, 
            &rect, 
            SDL_GetWindowPixelFormat (window), 
            surface.pixels,
            surface.pitch)) 
    {
        throw new SDLException ("SDL_RenderReadPixels: ");
    }

    g.m.m = new C[](rect.w*rect.h);
    g.m.w = rect.w;
    g.c   = 0xFFFFFFFF;

    // RENDER
    SDL_LockSurface (surface);

    // get pixels
    for (auto i=0; i<rect.w*rect.h; i++)
        g.m.m[i] = (cast(C*)surface.pixels)[i];

    // change pixels
    g.flow_stacked (pics,ids);

    // set pixels    
    for (auto i=0; i<rect.w*rect.h; i++)
        (cast(C*)surface.pixels)[i] = g.m.m[i];
    
    SDL_UnlockSurface (surface);

    //
    SDL_FreeSurface (surface);
}

