module pic;

import std.stdio : writeln;
import std.range;

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

/*
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
                render_block_borders (fbase,fsize,0xFFFF00FF);
            }

            i++;
            goto read_id;
        }

        exit:
            //
    }
*/
/*
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
*/
    void
    flow_3_stacked (ref Pics pics, ref Formats fmts, ref IDS ids, ref Base base, out Blocks blocks) {
        // ids
        //   (1 Start)
        //   (2 (1 Start))
        //   a  a       bb
        BlockId bid;
        // Zero block. Initial format
        _go_in_format (blocks,bid,fmts,0,base);

        //
        foreach (token; TokenReader (IdReader (ids)))
            final switch (token.type) {
                case TokenReader.Token.Type.A  : 
                    go_in_format (blocks,bid,fmts,token,base); 
                    break;
                case TokenReader.Token.Type.ID : 
                    render_pic (pics,blocks,bid,token,base); 
                    break;
                case TokenReader.Token.Type.B  : 
                    go_out_format (blocks,bid,fmts,base);
                    break;
            }
    }

    void
    go_in_format (ref Blocks blocks, ref BlockId bid, ref Formats fmts, ref TokenReader.Token token, ref Base base) {
        _go_in_format (blocks,bid,fmts,token.fid,base);
    }

    void
    _go_in_format (ref Blocks blocks, ref BlockId bid, ref Formats fmts, FormatID fid, ref Base base) {
        auto fmt = fid in fmts;

        Block block;
        block.fid    = fid;
        block.base   = base;
        block.prebid = bid;

        blocks ~= block;
        bid = blocks.length - 1;

        base += Base (fmt.padding_left,fmt.padding_top);
    }

    void
    render_pic (ref Pics pics, ref Blocks blocks, ref BlockId bid, ref TokenReader.Token token, ref Base base) {
        Size size;

        auto block = bid in blocks;

        render (pics[token.id],base,size);

        base.x += size.x;

        block.size.x += size.x;
        if (block.size.y<size.y) block.size.y = size.y;
    }

    void
    go_out_format (ref Blocks blocks, ref BlockId bid, ref Formats fmts, ref Base base) {
        auto block = bid in blocks;
        auto fmt   = block.fid in fmts;
        auto size =
            Size (fmt.padding_left,fmt.padding_top) +
            block.size +
            Size (fmt.padding_right,fmt.padding_bottom);

        render_block_borders (block.base,size,0xFF0000FF);

        if (bid == 0) {
            // 
        }
        else {
            auto preblock = block.prebid in blocks;
            preblock.size.x += size.x;
            if (preblock.size.y<size.y) preblock.size.y = size.y;

            base.x += fmt.padding_right;
            //base.y -= fmt.padding_top;

            //base.x  = block.base.x;
            //base.x += block.size.x;
            base.y  = block.base.y;

            bid = block.prebid;
        }
    }


    struct
    Block {
        FormatID fid;
        Base     base;
        Base     size;
        BlockId  prebid;
    }


    struct
    Blocks {
        Block[] _super;
        alias _super this;

        Block* 
        opBinaryRight (string op : "in")(BlockId i) {
            return &_super[i];
        }
    }

    alias 
    BlockId = size_t;

/*
    struct
    BlockRenderer {
        TokenReader r;
        Block front;
        Blocks blocks;

        alias 
        Blocks = Block[];

        void
        render () {
            render_content_flow (bg);

            render_padding_bg ();
              render_padding_bg_t ();
              render_padding_bg_l ();
              render_padding_bg_r ();
              render_padding_bg_b ();
        }

        void 
        popFront () {
            //
        }

        bool 
        empty () { 
            return r.empty; 
        }
    }
*/

    struct
    TokenReader {
        // ids
        //   (1 Start)
        //   (2 (1 Start))
        //   a  a       bb
        //    f  f
        //         -ids-
        IdReader r;
        Token    front;
        size_t   i;

        this (IDS ids) {
            r = IdReader (ids);
            read_token ();
        }

        this (IdReader id_reader) {
            r = id_reader;
            read_token ();
        }

        void
        popFront () {
            r.popFront (); i++;
            if (!r.empty) 
                read_token ();
            else
                {} // error
        }

        void
        read_token () {
            PicID _id = r.front;
            if (_id == '(') {
                FormatID fid;
                r.popFront(); i++;
                if (!r.empty) {
                    read_format (fid);
                    front.type = Token.Type.A;
                    front.fid  = fid;
                    front.i    = i;
                } else
                {
                    // error
                }
            }
            else
            if (_id == ')') {
                front.type = Token.Type.B;
                front.i    = i;
            }
            else {
                front.type = Token.Type.ID;
                front.id   = _id;
                front.i    = i;
            }
        }

        void
        read_format (out FormatID fid) {
            // current byte - format
            fid = r.front;
            r.popFront(); i++;
            // current byte - space
            //   next popFront() will to remove space
        }

        bool
        empty () {
            return r.empty;
        }

        struct 
        Token {
            PicID    id;
            FormatID fid;
            Type     type;
            size_t   i;

            enum Type : ubyte {
                ID = 0,
                A  = 1,
                B  = 2,
            }
        }
    }

    struct
    IdReader {
        IDS   r;
        PicID front () { return r.front; }
        bool  empty () { return r.empty; }
        void  popFront () { r.popFront; }
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
    render_block_borders (ref Base base, ref Size size, C c) {
        auto el = Pic.El (Pic.El.Type.CLOSED_LINE, [
            XY(), XY(size.x,0), size, XY(0,size.y) ]);
        Size el_size;
        render_closed_line (base, el, c, el_size);
    }


    void
    render_points (ref Pic pic, ref Base base, ref Pic.El el, out Size size) {
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
        auto pt = fmt.padding_top;
        auto pr = fmt.padding_right;
        auto pb = fmt.padding_bottom;
        auto pl = fmt.padding_left;

        fbase = 
            base + 
            XY (cast(short)pl,cast(short)pt);

        fsize = 
            size + 
            XY (cast(short)pl,cast(short)pt) + 
            XY (cast(short)pr,cast(short)pb);
    }
}


struct
Formats {
    Format[] _super;
    alias _super this;

    Format* 
    opBinaryRight (string op : "in")(FormatID i) {
        return &_super[i];
    }
}

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
    short padding_top;
    short padding_left;
    short padding_bottom;
    short padding_right;
}

// #  Format
// 0 
// 1  1 0 2 0   5 0  // Base    Attr: 1:padding_top 2:padding_right 3:p 4:p 5:magrin_top
// 2  1 10 2 10 3 0  // Button
// ...
// 255
// \2\1Start\0\0
//
// (G2,F2 (G1,F1 Start))
//
// e F2
//   e F1 
//     Start
//
// F1(Start)
// F2(F1(Start))

// Group
// \GStart\0 = save Group.1
// \g1\0     = ins  Group.1
// \f1\g1\0\0


// Attributes
enum AID : ubyte {
    _              = 0,
    //
    PADDING_TOP    = 1,
    PADDING_RIGHT  = 2,
    PADDING_BOTTOM = 3,
    PADDING_LEFT   = 4,
    //
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
