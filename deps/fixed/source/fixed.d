module fixed;
// Fixed-point type

//version = Fixed_std_math;  // hq

// 1.0 = INT.FRAC = 16-bit . 16-bit
//                = 32-bit          = int
//
// Example:
//   auto fixed_one  = Fixed(1,0);
//   auto fixed_zero = Fixed(0,0);
//   writeln (fixed_one);          // Fixed!16(1)
//   writeln (fixed_zero);         // Fixed!16(0)
//   writeln (fixed_one.to_int);   // 1
//   writeln (fixed_zero.to_int);  // 0
struct 
Fixed (int FRAC_BITS=16)  if (FRAC_BITS>0 && FRAC_BITS<(int.sizeof*8)) {
    int a;

    enum FRAC_UNIT       = ( 1 <<  FRAC_BITS );     // 0b1_0000_0000_0000_0000 = 0x10000 = 65536
    enum HALF_FRAC_UNIT  = ( 1 << (FRAC_BITS/2) );  // 0b__0000_0001_0000_0000 = 0x__100 = 256
    enum ROUND_MASK      = ( 1 << (FRAC_BITS-1) );  // 0b__1000_0000_0000_0000 = 0x_8000 = 32768
    alias T = typeof(this);
    enum FIXED_ONE       = T (FRAC_UNIT);
    enum FIXED_ZERO      = T (0);


    this (int _int, int _frac) {
        a = _int * FRAC_UNIT + _frac;
    }

    this (int _int) {
        a = _int;
    }

    this (T _fixed) {
        a = _fixed.a;
    }

    this (float _float) {
        //  1      ?  
        // --- = -----
        // 100   65536
        //
        //     1 * 65536
        // ? = ---------
        //        100
        a = cast(int)(_float * FRAC_UNIT);
    }

    this (double _double) {
        //  1      ?  
        // --- = -----
        // 100   65536
        //
        //     1 * 65536
        // ? = ---------
        //        100
        a = cast(int)(_double * FRAC_UNIT);
    }

    void
    opOpAssign (string op : "+")( T b ) {
        a += b.a;
    }

    void
    opOpAssign (string op : "-")( T b ) {
        a -= b.a;
    }

    T
    opBinary (string op : "+")( T b ) {
        return T (a + b.a);
    }

    T
    opBinary (string op : "-")( T b ) {
        return T (a - b.a);
    }

    int 
    opCmp (T b) {
        if (a == b.a)
            return 0;

        if (a > b.a)
            return 1;

        return -1;
    }

    T 
    opBinary (string op : "/") (T b) {
        version (Fixed_std_math) {   // high-quality
            return T ( to_double / b.to_double );
        } else {            
            return T ((a/T.HALF_FRAC_UNIT) / (b.a/b.HALF_FRAC_UNIT));
        }
    }

    T 
    opBinary (string op : "*",B) (B b) /*if (is (B : Fixed))*/ {
        version (Fixed_std_math) {   // high-quality
            return T ( to_double * b.to_double );
        } else {            
            return T (cast(int) ((cast(long)a) * b.a / b.FRAC_UNIT));
        }
    }

    T 
    opBinary (string op : "/") (int b) {
        return T (a/b);
    }

    T 
    opBinary (string op : "*") (int b) {
        return T (a*b);
    }

    T
    abs () {
        return T(-a);
    }

    short
    to_short () {
        return cast(short)((a + ROUND_MASK) / FRAC_UNIT);
    }

    int
    to_int () {
        return (a + ROUND_MASK) / FRAC_UNIT;
    }

    float
    to_float () {
        return (cast(float)a) / FRAC_UNIT;
    }

    double
    to_double () {
        return (cast(double)a) / FRAC_UNIT;
    }

    string 
    toString () {
        import std.format : format;
        return format!"%s(%d.%d fxd =%f float)" (T.stringof, a/FRAC_UNIT, a%FRAC_UNIT, to_float);
    }


    enum PI = T (3.1415926);
    // angle     circle
    //   0     = top
    //   1     = 1/49152
    //   2     = 1/24576
    //   4     = 1/12288
    //   8     = 1/6144
    //   16    = 1/3072
    //   32    = 1/1536
    //   64    = 1/768
    //   128   = 1/384
    //   256   = 1/192
    //   512   = 1/96
    //   1024  = 1/48
    //   2048  = 1/32
    //   4096  = 1/16
    //   8192  = 1/8          = 65536/8
    //   16386 = 1/4 right    = 65536/4
    //   32768 = 1/2 bottom   = 65536/2
    //   65536 = 1   top
    // cos 0     = 1
    // cos 65536 = 1
    // cos 32768 = -1
    // cos 16386 = 0
    //              _________
    // L(x,y)   = \/ xx + yy
    // R        = x
    //
    //            L(x,y)
    // cos(x,y) = ------  // соотношение длин  или коэф.уменьшения
    //              R
    //                
    //                x
    // cos xy   = ------------
    //              _________
    //            \/ xx + yy  
    //
    // sin xy   =  1 - cos xy
    //                    
    // circle.x = x cos xy
    // circle.y = y sin xy
    //             
    //                xx
    // circle.x = ------------
    //              _________
    //            \/ xx + yy  
    //
    //                xy
    // circle.y = ------------
    //              _________
    //            \/ xx + yy  
    struct
    CosSin {
        enum  CS_FRAC_BITS = 30;  // int.sizeof * 8 - 2 = 32 - 2 = 30  (1 bit - sign, 1 bit = 1)
        alias CSFixed = Fixed!CS_FRAC_BITS;
        CSFixed c;
        CSFixed s;

        static CosSin 
        from_r (int r) {
            // cos 1
            //   cos = 1 - 1/(2RR) = (2RR - 1) / (2RR)
            version (Fixed_std_math) {   // high-quality
                auto _2rr = 2*r*r;                
                auto c = cast(double)(_2rr - 1) / _2rr;
            } else {
                auto _2rr = 2*r*r;
                auto c = CSFixed (0,
                    (cast(long)CSFixed.FRAC_UNIT * (_2rr - 1)) / _2rr
                );
            }

            // sin 1     _______________
            //   sin = \/ (1 - cos*cos)
            version (Fixed_std_math) {   // high-quality
                import std.math : std_math_sqrt=sqrt;
                auto s = std_math_sqrt(1.0 - c*c);   
            } else {
                auto s = (CSFixed.FIXED_ONE - c*c).sqrt;
            }

            return typeof(this) (CSFixed (c),CSFixed (s));
        }
    }
    // L = PI/2 * R = 1
    // l = 1 / L = 1 / (PI/2 * R)

    // l = 1
    // L = l * PI/2 * R
    //       _________
    // l = \/ xx + yy  = 1 = xx + yy
    //     yy near 1
    //     y = sqrt near 1
    //     (65536-1)(65536-1)
    //     ?*? near 65535
    //     255*255 near 65535
    //     0.255 fixed!16
    //     0.0x00FF = 0000_0000_1111_1111
    //     255*255       = 65025
    //     0x00FF*0x00FF = 0xFE01
    //
    //     xx = 1 - yy

    T
    sqrt () {
        // Return the square root of n as a fixed point number.  It uses a
        // second order Newton-Raphson convergence.  This doubles the number
        // of significant figures on each iteration.
        //
        // Shift is the number of bits in the fractional part of the fixed
        // point number.

        // Initial guess - could do better than this
        long x     = FRAC_UNIT;                 // 32 bit type
        long n_one = cast(long)a << FRAC_BITS;  // 64 bit type
        long x_old;

        while (1) {
            x_old = x;
            x = (x + n_one / x) / 2;

            if (x == x_old)
                break;
        }

        return T (cast(int) (x));
    }


    // Integer square root
    // (using linear search, ascending)
    static uint 
    sqrt_default (uint _uint) {
        uint x  = 1;

        while (x*x <= _uint)
            x++;

        return x;
    }

    // Square root of integer
    static uint 
    sqrt_bin_search (uint _uint) {
        // Zero yields zero
        // One yields one
        if (_uint <= 1) 
            return _uint;

        // Initial estimate (must be too high)
        uint x0 = _uint / 2;

        // Update
        uint x1 = (x0 + _uint / x0) / 2;

        while (x1 < x0) {  // Bound check
            x0 = x1;
            x1 = (x0 + _uint / x0) / 2;
        }       

        return x0;
    }

    static uint 
    sqrt_sse (uint _uint) {
        // intrinsics
        //   __m128 V = _mm_set_ss(x);
        //   _mm_rsqrt_ss (V)
        // SSE
        //   rsqrtss xmm, xmm
        return 1;
    }

    A
    MAX(A,B)(A a, B b) {
        return (a>b) ? a : b;
    }
}

// xx + yy = 1
// yy + (R-x)(R-x) = RR
//
// xx + yy = 1
//      yy = 1 - xx
//
// yy + (R-x)(R-x) = RR
// yy     + (R-x)(R-x) = RR
// 1 - xx + (R-x)(R-x) = RR
// 1 - xx + RR - 2Rx + xx = RR
// 1      + RR - 2Rx      = RR
// 1           - 2Rx      =   
//             - 2Rx      = -1
//               2Rx      =  1
//                Rx      =  1/2
//                           1
//                 x      = ---- = 1/(2R)
//                           2R
//
// cos
// cos = (R-x) / R
// cos =  R/R-x/R
// cos =   1 -x/R
//   x = 1/(2R)
//
//            x 
// cos = 1 - ---
//            R 
//            
//            x     1
// cos = 1 - --- * ---
//            1     R
//            
//            1     1
// cos = 1 - --- * ---
//            2R    R
//            
//            1  
// cos = 1 - -----
//            2RR
//            
// cos = 1 - 1/(2RR)

// L = 6R        6 triangles with R length in 1 unit
// L = 12R      12 triangles with R length in 2 unit
// L = 6R units
// L = 6R squares
