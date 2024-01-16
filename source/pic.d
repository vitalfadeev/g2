module pic;

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
    flow_ (ref Pics pics, ref Formats fmts, ref IDS ids, ref FIDS fids, ref XY base, ref Sizes sizes) {
        assert (fids.length==pics.length);

        sizes.length = ids.length;
        bool _control = false;

        foreach (i,id; ids) {
            auto pic = pics[id];
            auto fid = fids[i];
            auto fmt = fmts[fid];  //
            Size size;
            render (pic, base, size);
            sizes[i] = size;
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
                case Pic.El.Type.CLOSED_LINE : render_closed_line (base, el, el_size); break;
                default:
            }

            if (el_size.x > size.x)
                size.x = el_size.x;

            if (el_size.y > size.y)
                size.y = el_size.y;
        }
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
            line (a,_b);
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
    render_closed_line (ref XY base, ref Pic.El el, out Size size) {
        XY  a = el.xys[0];
        XY _b;
        typeof(Size.x) maxx = a.x;
        typeof(Size.y) maxy = a.y;
        a += base;

        foreach (b; el.xys[1..$]) {
            _b = base + b;
            line (a,_b);
            a = _b;

            if (b.x > maxx)
                maxx = b.x;

            if (b.y > maxy)
                maxy = b.y;
        }

        line (a, base + el.xys[0]);

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
    Attr[AID] attrs;  // 255*4 = 1024 Bytes
}

// #  Format
// 0 
// 1  1 0 2 0   5 0  // Base    Attr: 1:padding_top 2:padding_right 3:p 4:p 5:magrin_top
// 2  1 10 2 10 3 0  // Button
// ...
// 255
// .Start
// 211111

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
