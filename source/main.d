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

    // □
    Pic pic_1;
    pic_1.els ~= Pic.El( Pic.El.Type.CLOSED_LINE, [
        XY(0,0), XY(100,0), XY(100,100), XY(0,100),
    ]);

    // ◇
    Pic pic_2; 
    pic_2.els ~= Pic.El( Pic.El.Type.CLOSED_LINE, [
        XY(50,0), XY(100,50), XY(50,100), XY(0,50),
    ]);

    // ◇ -
    Pic pic_3; 
    pic_3.els ~= Pic.El( Pic.El.Type.CLOSED_LINE, [
        XY(50,0), XY(100,25), XY(50,50), XY(0,25),
    ]);

    // ◇ |
    Pic pic_4; 
    pic_4.els ~= Pic.El( Pic.El.Type.CLOSED_LINE, [
        XY(25,0), XY(50,50), XY(25,100), XY(0,50),
    ]);

    // pictures table
    Pics pics;
    pics ~= pic_0;  // 0: pic_0
    pics ~= pic_1;  // 1: pic_1
    pics ~= pic_2;  // 2: pic_2
    pics ~= pic_3;  // 3: pic_3
    pics ~= pic_4;  // 3: pic_4

    // 3 picture_ids flow
    // \2\1Start\0\0
    version (_2) {
        IDS ids;
        ids ~= 1;
        ids ~= 1;
        ids ~= 2;
        ids ~= '\\';  // control
        ids ~= 2;     // fmt 2
        ids ~= 3;
        ids ~= 4;
        ids ~= '\\';  // control
        ids ~= 0;     // out fmt
    }

    //IDS ids;
    //ids ~= '(';   // (
    //ids ~= 2;     //  format
    //ids ~= ' ';   //  
    //ids ~= 1;     //  □
    //ids ~= 1;     //  □
    //ids ~= 1;     //  □
    //ids ~= 2;     //  ◇
    //ids ~= ')';   // )

    //IDS ids;
    //ids ~= '(';   // (
    //ids ~= 2;     //  format
    //ids ~= ' ';   //  
    //ids ~= 1;     //  □
    //ids ~= '(';   //  (
    //ids ~= 2;     //    format
    //ids ~= ' ';   //    
    //ids ~= 1;     //    □
    //ids ~= ')';   //  )
    //ids ~= 1;     //  □
    //ids ~= 2;     //  ◇
    //ids ~= ')';   // )

    IDS ids;
    ids ~= '(';   // (
    ids ~= 2;     //  format
    ids ~= ' ';   //  
    ids ~= 1;     //  □

    ids ~= '(';   //  (
    ids ~= 2;     //    format
    ids ~= ' ';   //    
    ids ~= 1;     //    □

    ids ~= '(';   //    (
    ids ~= 2;     //      format
    ids ~= ' ';   //    
    ids ~= 1;     //      □
    ids ~= ')';   //    )
    ids ~= 1;     //    □

    ids ~= ')';   //  )
    ids ~= 1;     //  □
    ids ~= ')';   // )

    // Format ids
    FIDS fids;
    fids ~= 1;
    fids ~= 1;
    fids ~= 1;
    fids ~= 1;
    fids ~= 1;

    // Formats
    Formats fmts;
    auto fmt_0 = Format();
    fmts ~= fmt_0;

    auto fmt_1 = Format();
    fmts ~= fmt_1;

    auto fmt_2 = Format();
    fmt_2.padding_top    = 20;
    fmt_2.padding_right  = 20;
    fmt_2.padding_bottom = 20;
    fmt_2.padding_left   = 20;
    fmts ~= fmt_2;

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
    XY      base;
    Bases   bases;
    Sizes   sizes;

    // RENDER
    SDL_LockSurface (surface);

    // get pixels
    for (auto i=0; i<rect.w*rect.h; i++)
        g.m.m[i] = (cast(C*)surface.pixels)[i];

    // change pixels
    //g.flow_stacked (pics,ids,base,sizes);
    //g.flow_2_stacked (pics,fmts,ids,base,bases,sizes);
    PicG.Blocks blocks;
    g.flow_3_stacked (pics,fmts,ids,base,blocks);

    // set pixels    
    for (auto i=0; i<rect.w*rect.h; i++)
        (cast(C*)surface.pixels)[i] = g.m.m[i];
    
    SDL_UnlockSurface (surface);

    //
    SDL_FreeSurface (surface);
}

