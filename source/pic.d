module pic;

import std.stdio : writeln;

//import g;
public import g;


alias 
PicID = size_t;

struct
Pic {
    El[] els;

    struct 
    El {
        Type type;  // LINE, CLOSED LINE, POINTS
        XY[] xys;

        enum Type {
            _,
            POINTS,
            LINE,
            CLOSED_LINE,
            LINES,
        }
    }
}


alias
Pics = Pic[];

alias 
IDS = PicID[];

alias
Sizes = Size[];


struct
PicG {
    G g;
    alias g this;

    void
    flow_2_stacked (ref Pics pics, ref Formats fmts, ref IDS ids, ref XY base, ref Sizes sizes) {
        import std.range;

        Size       size;
        PicID      preid;
        FormatID   fid;
        Format     fmt;
        FormatID[] fstack;

        sizes.length = ids.length;

        foreach (i,id; ids) {
            if (id=='\\') {     // control
                preid = id;
                continue;
            } 

            if (preid=='\\') {  // control
                fid = id;

                if (fid != 0) {    // in   : base += padding
                    fstack ~= fid;
                }
                else {             // out
                    fid = fstack.back ();  
                    fstack.popBack ();  
                }

                fmt = fmts[fid];
            }
            else {              // ID
                auto pic = pics[id];

                render_fmt (pic, base, fmt, size);

                base.x  += size.x;
                sizes[i] = size;
            }

            //
            preid = id;
        }
    }

    void
    flow (ref Pics pics, ref IDS ids, ref XY base, ref Sizes sizes) {
        sizes.length = ids.length;

        foreach (i,id; ids) {
            auto pic = pics[id];
            Size size;
            render (pic, base, size);
            sizes[i] = size;
        }
    }

    void
    flow_stacked (ref Pics pics, ref IDS ids, ref XY base, ref Sizes sizes) {
        sizes.length = ids.length;

        foreach (i,id; ids) {
            auto pic = pics[id];
            Size size;
            render (pic, base, size);
            base.x  += size.x;
            sizes[i] = size;
        }
    }

    void
    render (ref Pic pic, ref XY base, out Size size) {
        Size el_size;

        foreach (el; pic.els) {
            switch (el.type) {
                case Pic.El.Type.POINTS      : render_points (pic, base, el, el_size); break;
                case Pic.El.Type.LINE        : render_line (base, el, el_size); break;
                case Pic.El.Type.CLOSED_LINE : render_closed_line (base, el, c, el_size); break;
                default:
            }

            if (el_size.x > size.x)
                size.x = el_size.x;

            if (el_size.y > size.y)
                size.y = el_size.y;
        }
    }

    void
    render_fmt (ref Pic pic, ref XY base, ref Format fmt, out Size size) {
        Size el_size;
        auto pt = fmt.attrs[AID.PADDING_TOP];
        auto pr = fmt.attrs[AID.PADDING_RIGHT];
        auto pb = fmt.attrs[AID.PADDING_BOTTOM];
        auto pl = fmt.attrs[AID.PADDING_LEFT];

        auto pbase = 
            base + 
            XY (cast(short)pl,cast(short)pt);

        render (pic, pbase, size);

        auto psize = 
            size + 
            XY (cast(short)pl,cast(short)pt) + 
            XY (cast(short)pr,cast(short)pb);
        render_borders (base,psize,0xFFFF00FF);
        render_content_borders (pbase,size,0xFF00FFFF);
    }

    void
    render_borders (XY base, Size size, C c) {
        auto el = Pic.El (Pic.El.Type.CLOSED_LINE, [
            XY(), XY(size.x,0), size, XY(0,size.y) ]);
        Size el_size;
        render_closed_line (base, el, c, el_size);
    }

    void
    render_content_borders (XY base, Size size, C c) {
        auto el = Pic.El (Pic.El.Type.CLOSED_LINE, [
            XY(), XY(size.x,0), size, XY(0,size.y) ]);
        Size el_size;
        render_closed_line (base, el, c, el_size);
    }

    void
    render_points (ref Pic pic, ref XY base, ref Pic.El el, out Size size) {
        typeof(Size.x) maxx;
        typeof(Size.y) maxy;

        foreach (xy; el.xys) {
            point (base+xy);

            if (xy.x > maxx)
                maxx = xy.x;

            if (xy.y > maxy)
                maxy = xy.y;
        }

        size.x = maxx;
        size.y = maxy;
    }

    void
    render_line (ref XY base, ref Pic.El el, out Size size) {
        XY  a = el.xys[0];
        XY _b;
        typeof(Size.x) maxx = a.x;
        typeof(Size.y) maxy = a.y;
        a += base;

        foreach (b; el.xys[1..$]) {
            _b = base + b;
            line (a,_b,c);
            a = _b;

            if (b.x > maxx)
                maxx = b.x;

            if (b.y > maxy)
                maxy = b.y;
        }

        size.x = maxx;
        size.y = maxy;
    }

    void
    render_closed_line (ref XY base, ref Pic.El el, C c, out Size size) {
        XY  a = el.xys[0];
        XY _b;
        typeof(Size.x) maxx = a.x;
        typeof(Size.y) maxy = a.y;
        a += base;

        foreach (b; el.xys[1..$]) {
            _b = base + b;
            line (a,_b,c);
            a = _b;

            if (b.x > maxx)
                maxx = b.x;

            if (b.y > maxy)
                maxy = b.y;
        }

        line (a, base + el.xys[0], c);

        size.x = maxx;
        size.y = maxy;
    }
}


alias
Formats = Format[];

alias
FormatID = size_t;

alias 
FIDS = FormatID[];

struct
Format {
    // padding
    // margin
    // fg
    // bg
    // border
    Attr[AID.max] attrs;  // 255*4 = 1024 Bytes
}

// #  Format
// 0 
// 1  1 0 2 0   5 0  // Base    Attr: 1:padding_top 2:padding_right 3:p 4:p 5:magrin_top
// 2  1 10 2 10 3 0  // Button
// ...
// 255
// \2\1Start\0\0

// Attributes
enum AID : ubyte {
    _              = 0,
    PADDING_TOP    = 1,
    PADDING_RIGHT  = 2,
    PADDING_BOTTOM = 3,
    PADDING_LEFT   = 4,
    MARGIN_TOP     = 5,
    MARGIN_RIGHT   = 6,
    MARGIN_BOTTOM  = 7,
    MARGIN_LEFT    = 8,
}

alias
Attr = int;

// Format
enum FID : ubyte {
    BASE   = 0,
    BUTTON = 1,
}
