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
    flow (ref Pics pics, ref IDS ids) {
        XY base;

        foreach (id; ids) {
            auto pic = pics[id];
            Size size;
            render (pic, base, size);
        }
    }

    void
    flow_stacked (ref Pics pics, ref IDS ids) {
        XY base;

        foreach (id; ids) {
            auto pic = pics[id];
            Size size;
            render (pic, base, size);
            base.x += size.x;
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
        XY  a = base + el.xys[0];
        XY _b;
        typeof(Size.x) maxx = a.x;
        typeof(Size.y) maxy = a.y;

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
        XY  a = base + el.xys[0];
        XY _b;
        typeof(Size.x) maxx = a.x;
        typeof(Size.y) maxy = a.y;

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
