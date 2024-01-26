module bitmap_font;

struct
BitPic {
    ubyte[32] m;  // 16x16  = 4x64  = 8x32
}

struct
_MonoBitPics(ushort NChars) {
    // char size
    ubyte  xsize;  // bits
    ubyte  ysize;  // bits
    // total
    ushort chars = NChars;
    // bits
    ubyte[NChars] m;  // by 8 bit
}

alias
MonoBitPics = _MonoBitPics!128;


void
save_file (ref MonoBitPics bps, string fname) {
    import std.stdio;
    auto f = File (fname);
    f.rawWrite ((&bps)[0..1]);
}

void
load_file (string fname, out MonoBitPics bps) {
    import std.stdio;
    auto f = File (fname);
    f.rawRead ((&bps)[0..1]);
}


// Font
// Bitmap font
// ........ ........ 16x16  = 32 Bytes  = 4 * 64-bit read mem
// ........ ........
// ........ ........
// ........ ........
// ........ ........
// ........ ........
// ........ ........
// ........ ........
// ........ ........ //
// ........ ........
// ........ ........
// ........ ........
// ........ ........
// ........ ........
// ........ ........
// ........ ........
