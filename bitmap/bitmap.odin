/*
 *  @Name:     bitmap
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 28-11-2017 00:10:03 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 20-08-2018 23:41:59 UTC-5
 *  
 *  @Description:
 *  
 */

package bitmap

import "core:bits"
import "core:mem"
import "core:os"



using Compression :: enum u32 {
    RGB             = 0,
    RLE8            = 1,
    RLE4            = 2,
    Bitfields       = 3,
    JPEG            = 4,
    PNG             = 5,
    Alpha_Bitfields = 6,
    CMYK            = 11,
    CMYKRLE8        = 12,
    CMYKRLE4        = 13,
}

Header :: struct {
    magic:         u16,
    file_size:     u32,
    _:             [2]u16,
    offset:        u32,
    info_size:     u32,
    width:         i32,
    height:        i32,
    planes:        u16,
    bits:          u16,
    compression:   Compression,
    size:          u32,
    ppm_h:         i32,
    ppm_v:         i32,
    palette:       u32,
    important:     u32,
}

load :: proc(path: string, buf: []u32 = nil) -> (w, h: int, px: []u32) {
    if bytes, ok := os.read_entire_file(path); ok {
        defer delete(bytes);

        bmp := cast(^Header) &bytes[0];
        
        if buf == nil {
            buf = make([]u32, bmp.width*bmp.height);
        }

        pixels := mem.slice_ptr((^u32)(mem.ptr_offset(&bytes[0], int(bmp.offset))), int(bmp.width*bmp.height));
    
        for _, i in buf {
            buf[i] = bits.byte_swap(pixels[i]);
        }
        
        return cast(int) bmp.width, cast(int) bmp.height, buf;
    }

    return 0, 0, nil;
}

save :: proc(path: string, w, h: int, buf: []u32, compression := Bitfields) -> bool {
    if file, err := os.open(path, os.O_RDONLY | os.O_CREATE); err == os.ERROR_NONE {
        defer os.close(file);

        header := Header { // @note(bpunsky): *lots* of magic going on here
            magic       = 0x4042,
            file_size   = (u32)(size_of(Header) + len(buf)),
            offset      = 54,
            info_size   = 40,
            width       = (i32)(w),
            height      = (i32)(h),
            planes      = 1,
            bits        = 32,
            compression = compression,
            size        = (u32)(w*h),
        };

        tmp := make([]u8, size_of(Header) + len(buf) * size_of(u32));
        defer delete(tmp);
        
        mem.copy(&tmp[0], &header, size_of(header));

        for px, i in buf {
            mem.ptr_offset(cast(^u32) mem.ptr_offset(&tmp[0], size_of(header)), i)^ = bits.byte_swap(px);
        }

        os.write(file, tmp);

        return true;
    }

    return false;
}
