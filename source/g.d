module g;


struct
G {
    CMAP m;
    C    c;


    // G primitives
    void
    point (XY a) {
        m.point (a,c);
    }

    void
    line (XY a, XY b) {
        if (a.y == b.y)
            hline (a,b);
        else if (a.x == b.x)
            vline (a,b);
        else
            dline (a,b);
    }

    void
    hline (XY a, XY b) {
        m.hline (a,b,c);
    }

    void
    vline (XY a, XY b) {
        m.vline (a,b,c);
    }

    void
    dline (XY a, XY b) {
        m.dline (a,b,c);
    }
}


//struct
//BasedG {
//    G g;
//    alias g this;
//    XY base;
//}


alias 
C = uint;

struct
CMAP {
    C[] m;
    int w;

    void
    opIndexAssign (C c, XY a) {
        m[a.y*w + a.x] = c;
    }

    void
    point (XY a, C c) {
        m[a.y*w + a.x] = c;
    }

    void
    hline (XY a, XY b, C c) {
        auto _m     = m.ptr + a.y*w + a.x;
        auto  limit = _m + (b.x-a.x);
        auto _inc = (a.x < b.x) ? 1 : - 1;

        for (; _m!=limit; _m+=_inc)
            *_m = c;
    }

    void
    vline (XY a, XY b, C c) {
        auto _m     = m.ptr + a.y*w + a.x;
        auto  limit = _m + (b.y-a.y)*w;
        auto _inc = (a.y < b.y) ? w : - w;

        for (; _m!=limit; _m+=_inc)
            *_m = c;
    }

    void
    dline (XY a, XY b, C c) {
        //auto _m     = m.ptr + a.y*w + a.x;
        //auto  limit = _m + (b.y-a.y)*w;
        //auto _inc = (a.y < b.y) ? w : - w;

        //for (; _m!=limit; _m+=_inc)
        //    *_m = c;
    }
}


struct
XY {
    short x;
    short y;

    XY
    opBinary (string op: "+") (XY b) {
        return XY (cast(short)(x+b.x), cast(short)(y+b.y));
    }

    void
    opOpAssign (string op: "+") (XY b) {
        x += cast(short)b.x;
        y += cast(short)b.y;
    }
}

alias
Size = XY;
