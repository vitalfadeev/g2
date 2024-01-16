module g;

import fixed;
import std.stdio : writeln;


alias 
Fixed = fixed.Fixed!16;

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
        assert (a.y==b.y);

        auto _m     = m.ptr + a.y*w + a.x;
        auto  limit = _m + (b.x-a.x);
        auto _inc = (a.x < b.x) ? 1 : - 1;

        for (; _m!=limit; _m+=_inc)
            *_m = c;
    }

    void
    vline (XY a, XY b, C c) {
        assert (a.x==b.x);

        auto _w     = w;
        auto _m     = m.ptr + a.y*_w + a.x;
        auto  limit = _m + (b.y-a.y)*_w;
        auto _inc = (a.y < b.y) ? _w : - _w;

        for (; _m!=limit; _m+=_inc)
            *_m = c;
    }

    void
    dline (XY a, XY b, C c) {
        auto ba = (b-a).abs;

        if (ba.x >= ba.y) {
            if (a.x<b.x)
                dline_by_x (a, b, c);
            else
                dline_by_x_rev (a, b, c);
        }
        else {
            if (a.y<b.y)
                dline_by_y (a, b, c);
            else
                dline_by_y_rev (a, b, c);
        }
    }

    void
    dline_by_x (XY a, XY b, C c) {
        assert (a.x<=b.x);

        auto _w = w;
        auto ba = b-a;
        auto x  = a.x;
        auto limit = b.x;
        auto y_inc = Fixed (ba.y,0) / ba.x;
        auto y = Fixed (a.y,0);

        for (; x!=limit; x++) {
            y += y_inc;
            m[y.to_int*_w + x] = c;
        }
    }

    void
    dline_by_x_rev (XY a, XY b, C c) {
        assert (a.x>=b.x);

        auto _w = w;
        auto ba = b-a;
        auto x  = a.x;
        auto limit = b.x;
        auto y_inc = Fixed (ba.y,0) / -ba.x;
        auto y = Fixed (a.y,0);

        for (; x!=limit; x--) {
            y += y_inc;
            m[y.to_int*_w + x] = c;
        }
    }

    void
    dline_by_y (XY a, XY b, C c) {
        assert (a.y<=b.y);

        auto _w = w;
        auto ba = b-a;
        auto y  = a.y;
        auto limit = b.y;
        auto x_inc = Fixed (ba.x,0) / ba.y;
        auto x = Fixed (a.x,0);
        writeln (x_inc);

        for (; y!=limit; y++) {
            x += x_inc;
            m[y*_w + x.to_int] = c;
        }
    }

    void
    dline_by_y_rev (XY a, XY b, C c) {
        assert (a.y>b.y);

        auto _w = w;
        auto ba = b-a;
        auto y  = a.y;
        auto limit = b.y;
        auto x_inc = Fixed (ba.x,0) / -ba.y;
        auto x = Fixed (a.x,0);
        writeln (x_inc);

        for (; y!=limit; y--) {
            x += x_inc;
            m[y*_w + x.to_int] = c;
        }
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

    XY
    opBinary (string op: "-") (XY b) {
        return XY (cast(short)(x-b.x), cast(short)(y-b.y));
    }

    void
    opOpAssign (string op: "+") (XY b) {
        x += cast(short)b.x;
        y += cast(short)b.y;
    }

    XY
    abs () {
        return XY (cast(short)(x>=0?x:-x), cast(short)(y>=0?y:-y));
    }
}

alias
Size = XY;
