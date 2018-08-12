    #include <stdio.h>
    #include <stdint.h>

    typedef int64_t _int;
    typedef int64_t _i64;
    typedef int32_t _i32;
    typedef int16_t _i16;
    typedef int8_t _i8;
    typedef uint64_t _uint;
    typedef uint64_t _u64;
    typedef uint32_t _u32;
    typedef uint16_t _u16;
    typedef uint8_t _u8;
    typedef int64_t _bool;
    typedef int64_t _b64;
    typedef int32_t _b32;
    typedef int16_t _b16;
    typedef int8_t _b8;
    typedef double _f64;
    typedef float _f32;
    typedef struct{uint8_t *data; uint64_t len;} _string;
    typedef uint8_t * _ztring;
    typedef void (*type0)(    _ztring _fmt,     _int _i);

int main(int argc, char **argv)     {
        _int _foo = 123;
        _int _bar = 321;
        {
            if (1)
            {
                auto t0 = _bar * 123;
                auto t1 = t0 / 5;
                auto t2 = _foo + t1;
                _foo = t2;
            }
        }
        {
            auto _i = 0;
            while (1)
            {
                auto t3 = _i < 10;
                if (!t3) break;
                {
                    _bar += 2;
                }
                _i += 1;
            }
        }
        type0 _print_int = printf;
        _print_int("%lld\n", _foo);
        _print_int("%lld\n", _bar);
        auto t4 = _foo + _bar;
        _print_int("%lld\n", t4);
    }
