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
    flow_2_stacked (ref Pics pics, ref Formats fmts, ref IDS ids, ref Base base, out Bases bases, out Sizes sizes) {
        import std.range;

        PicID      id;
        Size       size;
        FormatID   fid;
        size_t     i;
        Format     fmt;
        FormatID[] fstack;
        // for format's borders
        Base[]     bstack;
        Size       csize;
        Base       fbase;
        Size       fsize;

        auto ids_iterator = ids;
        sizes.length = ids_iterator.length;
        bases.length = ids_iterator.length;

        //
        read_id: {
            if (ids_iterator.empty)
                goto exit;

            id = ids_iterator.front;
            ids_iterator.popFront();

            if (id=='\\') {
                i++;
                goto read_control;
            }
            else {
                auto pic = pics[id];

                render (pic,base,size);

                // for content's borders
                render_content_borders (base,size,0xFF00FFFF);

                // save base
                // save size
                bases[i] = base;
                sizes[i] = size;

                // step to right
                base.x += size.x;

                // all content size
                csize.x += size.x;
                if (size.y>csize.y)
                    csize.y = size.y;
            }

            i++;
            goto read_id;
        }

        read_control: {
            if (ids_iterator.empty)
                goto exit;

            id = ids_iterator.front;
            ids_iterator.popFront();

            if (id != 0) {    // in
                // format id
                fid = id;
                fstack ~= fid;
                fmt = fmts[fid];

                // for format's borders
                bstack ~= base;

                //
                format (fmt, base, size, fbase, fsize);
                base  = fbase;
                csize = csize.init;
            }
            else {            // out
                fid = fstack.back;
                fstack.popBack ();  
                fmt = fmts[fid];

                // for format's borders
                format (fmt, base, csize, fbase, fsize);
                fbase = bstack.back;
                bstack.popBack ();
                render_borders (fbase,fsize,0xFFFF00FF);
            }

            i++;
            goto read_id;
        }

        exit:
            //
    }

    void
    flow (ref Pics pics, ref IDS ids, ref Base base, ref Sizes sizes) {
        sizes.length = ids.length;

        foreach (i,id; ids) {
            auto pic = pics[id];
            Size size;
            render (pic, base, size);
            sizes[i] = size;
        }
    }

    void
    flow_stacked (ref Pics pics, ref IDS ids, ref Base base, ref Sizes sizes) {
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
    render (ref Pic pic, ref Base base, out Size size) {
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

    void
    format (ref Format fmt, ref Base base, ref Size size, out Base fbase, out Size fsize) {
        auto pt = fmt.attrs[AID.PADDING_TOP];
        auto pr = fmt.attrs[AID.PADDING_RIGHT];
        auto pb = fmt.attrs[AID.PADDING_BOTTOM];
        auto pl = fmt.attrs[AID.PADDING_LEFT];

        fbase = 
            base + 
            XY (cast(short)pl,cast(short)pt);

        fsize = 
            size + 
            XY (cast(short)pl,cast(short)pt) + 
            XY (cast(short)pr,cast(short)pb);
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
