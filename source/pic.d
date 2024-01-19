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
        blocks.length = ids.length;
        size_t parent_block;
        Size   size;   // one pic  size
        Size   csize;  // all pics size. content size

        //
        foreach (token; TokenReader (IdReader (ids)))
            final switch (token.type) {
                case TokenReader.Token.Type.A  : render_block_start (pics,fmts,base,token,blocks,parent_block); break;
                case TokenReader.Token.Type.ID : render_id (pics,fmts,base,size,token,blocks,parent_block); csize.x+=size.x; if (csize.y<size.y) csize.y=size.y; break;
                case TokenReader.Token.Type.B  : render_block_end (pics,fmts,base,token,blocks,parent_block,csize); break;
            }
    }

    void
    render_block_start (ref Pics pics, ref Formats fmts, ref Base base, ref TokenReader.Token token, ref Blocks blocks, ref size_t parent_block) {
        // save base
        // base + padding
        // new block will parent
        auto fid = token.fid;
        auto fmt = fmts[fid];
        auto i   = token.i;
        Base cbase;
        content_base (fmt,base,cbase);
        save_block (blocks,i,base,fid,parent_block,cbase);
        set_new_parent (parent_block,i);
        set_new_base (base,cbase);
    }


    void
    render_id (ref Pics pics, ref Formats fmts, ref Base base, ref Size size, TokenReader.Token token, ref Blocks blocks, size_t parent_block) {
        auto i   = token.i;
        auto pic = pics[token.id];
        auto fid = token.fid;

        render (pic,base,size);
        render_content_borders (base,size,0xFF00FFFF);

        next_base (base,size);
        save_block_c (blocks,i,base,size,fid,parent_block);
    }

    void
    render_content_borders (XY base, Size size, C c) {
        auto el = Pic.El (Pic.El.Type.CLOSED_LINE, [
            XY(), XY(size.x,0), size, XY(0,size.y) ]);
        Size el_size;
        render_closed_line (base, el, c, el_size);
    }

    void
    next_base (ref Base base, ref Size size) {
        base.x += size.x;
    }

    void
    content_base (ref Format fmt, ref Base base, ref Base cbase) {
        cbase = base + XY (fmt.padding_left,fmt.padding_top);
    }

    void
    set_new_parent (ref size_t parent_block, size_t i) {
        parent_block = i;
    }

    void
    set_new_base (ref Base base, ref Base cbase) {
        base = cbase;
    }

    void
    save_block (ref Blocks blocks, size_t i, Base base, FormatID fid, size_t parent_block, Base cbase) {
        blocks[i] = Block (base,Size(),fid,parent_block,cbase);
    }

    void
    save_block_c (ref Blocks blocks, size_t i, Base base, Size size, FormatID fid, size_t parent_block) {
        blocks[i] = Block (base,size,fid,parent_block);
    }


    void
    render_block_end (ref Pics pics, ref Formats fmts, ref Base base, TokenReader.Token token, ref Blocks blocks, ref size_t parent_block, ref Size csize) {
        auto block = blocks[parent_block];
        update_block_size (fmts,block,csize);
        render_block_borders (block.base,block.size,0xFFFF00FF);
        restore_parent (block,parent_block);
    }

    void
    update_block_size (ref Formats fmts, ref Block block, ref Size csize) {
        auto fmt    = fmts[block.fid];
        block.size  = 
            XY (fmt.padding_left,fmt.padding_top) + 
            csize + 
            XY (fmt.padding_right,fmt.padding_bottom);
        block.csize = csize;
    }

    void
    restore_parent (ref Block block, ref size_t parent_block) {
        parent_block = block.parent_block;
    }


    struct
    Block {
        Base     base;
        Size     size;
        FormatID fid;
        size_t   parent_block;
        Base     cbase;  // content base
        Size     csize;  // content size
    }


    alias
    Blocks = Block[];

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
    render_block_borders (Base base, Size size, C c) {
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
