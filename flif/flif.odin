when ODIN_OS == "windows" {
    foreign import "libflif.lib"
} else {
    foreign import "libflif"
}

import "core:os.odin"



/////////////////////////////
///
/// COMMON
/////////////////////////////

Image :: rawptr;

@(link_prefix="flif_")
foreign libflif {
    @(link_name="flif_create_image")         create_image         :: proc(width, height: u32) -> Image ---; // RGBA
    @(link_name="flif_create_image_RGB")     create_image_rgb     :: proc(width, height: u32) -> Image ---;
    @(link_name="flif_create_image_GRAY")    create_image_gray    :: proc(width, height: u32) -> Image ---;
    @(link_name="flif_create_image_GRAY16")  create_image_gray16  :: proc(width, height: u32) -> Image ---;
    @(link_name="flif_create_image_PALETTE") create_image_palette :: proc(width, height: u32) -> Image ---;
    @(link_name="flif_create_image_HDR")     create_image_hdr     :: proc(width, height: u32) -> Image ---;

    @(link_name="flif_import_image_RGBA")    import_image_rgba    :: proc(width, height: u32, rgba: rawptr, rgba_stride: u32) -> Image ---;
    @(link_name="flif_import_image_RGB")     import_image_rgb     :: proc(width, height: u32, rgb:  rawptr, rgb_stride:  u32) -> Image ---;
    @(link_name="flif_import_image_GRAY")    import_image_gray    :: proc(width, height: u32, gray: rawptr, gray_stride: u32) -> Image ---;
    @(link_name="flif_import_image_GRAY16")  import_image_gray16  :: proc(width, height: u32, gray: rawptr, gray_stride: u32) -> Image ---;
    @(link_name="flif_import_image_PALETTE") import_image_palette :: proc(width, height: u32, gray: rawptr, gray_stride: u32) -> Image ---;
    @(link_name="flif_import_image_HDR")     import_image_hdr     :: proc(width, height: i32, hdr:  rawptr, hdr_stride:  u32) -> Image ---;

    @(link_name="flif_destroy_image") destroy :: proc(image: Image) ---;

    @(link_name="flif_image_get_width")        get_width        :: proc(image: Image)                                     -> u32 ---;
    @(link_name="flif_image_get_height")       get_height       :: proc(image: Image)                                     -> u32 ---;
    @(link_name="flif_image_get_nb_channels")  get_nb_channels  :: proc(image: Image)                                     -> u8  ---;
    @(link_name="flif_image_get_depth")        get_depth        :: proc(image: Image)                                     -> u8  ---;
    @(link_name="flif_image_get_palette_size") get_palette_size :: proc(image: Image)                                     -> u32 ---; // 0 = no palette, 1-256 = nb of colors in palette
    @(link_name="flif_image_get_palette")      get_palette      :: proc(image: Image, buffer: rawptr)                            ---; // puts RGBA colors in buffer (4*palette_size bytes)
    @(link_name="flif_image_set_palette")      set_palette      :: proc(image: Image, buffer: rawptr, palette_size: u32)         ---; // puts RGBA colors in buffer (4*palette_size bytes)
    @(link_name="flif_image_get_frame_delay")  get_frame_delay  :: proc(image: Image)                                     -> u32 ---;
    @(link_name="flif_image_set_frame_delay")  set_frame_delay  :: proc(image: Image, delay: u32)                                ---;

    @(link_name="flif_image_set_metadata")  set_metadata  :: proc(image: Image, chunkname: ^u8, data: ^u8,  length: uint)        ---;
    @(link_name="flif_image_get_metadata")  get_metadata  :: proc(image: Image, chunkname: ^u8, data: ^^u8, length: ^uint) -> u8 ---;
    @(link_name="flif_image_free_metadata") free_metadata :: proc(image: Image, data: ^u8)                                       ---;

    @(link_name="flif_image_write_row_PALETTE8") write_row_palette8 :: proc(image: Image, row: u32, buffer: rawptr, buffer_size_bytes: uint) ---;
    @(link_name="flif_image_read_row_PALETTE8")  read_row_palette8  :: proc(image: Image, row: u32, buffer: rawptr, buffer_size_bytes: uint) ---;

    @(link_name="flif_image_write_row_GRAY8")    write_row_GRAY8    :: proc(image: Image, row: u32, buffer: rawptr, buffer_size_bytes: uint) ---;
    @(link_name="flif_image_read_row_GRAY8")     read_row_GRAY8     :: proc(image: Image, row: u32, buffer: rawptr, buffer_size_bytes: uint) ---;

    @(link_name="flif_image_write_row_GRAY16")   write_row_gray16   :: proc(image: Image, row: u32, buffer: rawptr, buffer_size_bytes: uint) ---;
    @(link_name="flif_image_read_row_GRAY16")    read_row_gray16    :: proc(image: Image, row: u32, buffer: rawptr, buffer_size_bytes: uint) ---;

    @(link_name="flif_image_write_row_RGBA8")    write_row_rgba8    :: proc(image: Image, row: u32, buffer: rawptr, buffer_size_bytes: uint) ---;
    @(link_name="flif_image_read_row_RGBA8")     read_row_rgba8     :: proc(image: Image, row: u32, buffer: rawptr, buffer_size_bytes: uint) ---;

    @(link_name="flif_image_write_row_RGBA16")   write_row_rgba16   :: proc(image: Image, row: u32, buffer: rawptr, buffer_size_bytes: uint) ---;
    @(link_name="flif_image_read_row_RGBA16")    read_row_rgba16    :: proc(image: Image, row: u32, buffer: rawptr, buffer_size_bytes: uint) ---;

    @(link_name="flif_free_memory") free_memory :: proc(buffer: rawptr) ---;
}



/////////////////////////////
///
/// ENCODING
/////////////////////////////

Encoder :: rawptr; // @todo: deopaquify

foreign libflif {
    // initialize a FLIF encoder
    @(link_name="flif_create_encoder") create_encoder :: proc() -> Encoder ---;

    // give it an image to encode; add more than one image to encode an animation; it will CLONE the image
    // (so the input image is not touched and you have to call flif_destroy_image on it yourself to free that memory)
    @(link_name="flif_encoder_add_image") add_image :: proc(encoder: Encoder, image: Image) ---;

    // give it an image to encode; add more than one image to encode an animation; it will MOVE the input image
    // (input image becomes invalid during encode and flif_destroy_encoder will free it)
    @(link_name="flif_encoder_add_image_move") add_image_move :: proc(encoder: Encoder, image: Image) ---;

    // encode to a file
    @(link_name="flif_encoder_encode_file") encode_file :: proc(encoder: Encoder, filename: ^u8) -> i32 ---;

    // encode to memory (afterwards, buffer will point to the blob and buffer_size_bytes contains its size)
    @(link_name="flif_encoder_encode_memory") encode_memory :: proc(encoder: Encoder, buffer: ^rawptr, buffer_size_bytes: ^uint) -> i32 ---;

    // release an encoder (has to be called to avoid memory leaks)
    @(link_name="flif_destroy_encoder") destroy :: proc(encoder: Encoder) ---;

    // encoder options (these are all optional, the defaults should be fine)
    @(link_name="flif_encoder_set_interlaced")          set_interlaced          :: proc(encoder: Encoder, interlaced: u32)    ---; // 0 = -N, 1 = -I (default: -I)
    @(link_name="flif_encoder_set_learn_repeat")        set_learn_repeat        :: proc(encoder: Encoder, learn_repeats: u32) ---; // default: 2 (-R)
    @(link_name="flif_encoder_set_auto_color_buckets")  set_auto_color_buckets  :: proc(encoder: Encoder, acb: u32)           ---; // 0 = -B, 1 = default
    @(link_name="flif_encoder_set_palette_size")        set_palette_size        :: proc(encoder: Encoder, palette_size: i32)  ---; // default: 512  (max palette size)
    @(link_name="flif_encoder_set_lookback")            set_lookback            :: proc(encoder: Encoder, lookback: i32)      ---; // default: 1 (-L)
    @(link_name="flif_encoder_set_divisor")             set_divisor             :: proc(encoder: Encoder, divisor: i32)       ---; // default: 30 (-D)
    @(link_name="flif_encoder_set_min_size")            set_min_size            :: proc(encoder: Encoder, min_size: i32)      ---; // default: 50 (-M)
    @(link_name="flif_encoder_set_split_threshold")     set_split_threshold     :: proc(encoder: Encoder, threshold: i32)     ---; // default: 64 (-T)
    @(link_name="flif_encoder_set_alpha_zero_lossless") set_alpha_zero_lossless :: proc(encoder: Encoder)                     ---; // 0 = default, 1 = -K
    @(link_name="flif_encoder_set_chance_cutoff")       set_chance_cutoff       :: proc(encoder: Encoder, cutoff: i32)        ---; // default: 2  (-X)
    @(link_name="flif_encoder_set_chance_alpha")        set_chance_alpha        :: proc(encoder: Encoder, alpha: i32)         ---; // default: 19 (-Z)
    @(link_name="flif_encoder_set_crc_check")           set_crc_check           :: proc(encoder: Encoder, crc_check: u32)     ---; // 0 = no CRC, 1 = add CRC
    @(link_name="flif_encoder_set_channel_compact")     set_channel_compact     :: proc(encoder: Encoder, plc: u32)           ---; // 0 = -C, 1 = default
    @(link_name="flif_encoder_set_ycocg")               set_ycocg               :: proc(encoder: Encoder, ycocg: u32)         ---; // 0 = -Y, 1 = default
    @(link_name="flif_encoder_set_frame_shape")         set_frame_shape         :: proc(encoder: Encoder, frs: u32)           ---; // 0 = -S, 1 = default

    //set amount of quality loss, 0 for no loss, 100 for maximum loss, negative values indicate adaptive lossy (second image should be the saliency map)
    @(link_name="flif_encoder_set_lossy") set_lossy :: proc(encoder: Encoder, loss: i32) ---; // default: 0 (lossless)
}



///////////////////////////////
///
/// DECODING
///////////////////////////////

Callback :: #type proc "c" (quality: u32, bytes_read: i64, decode_over: u8, user_date: rawptr, ctx: rawptr) -> u32;

Decoder :: rawptr;
Info    :: rawptr;

foreign libflif {
    // initialize a FLIF decoder
    @(link_name="flif_create_decoder") create_decoder :: proc() -> Decoder ---;

    // decode a given FLIF file
    @(link_name="flif_decoder_decode_file") decode_file :: proc(decoder: Decoder, filename: ^u8) -> i32 ---;
    // decode a FLIF blob in memory: buffer should point to the blob and buffer_size_bytes should be its size
    @(link_name="flif_decoder_decode_memory") decode_memory :: proc(decoder: Decoder, buffer: rawptr, buffer_size_bytes: uint) -> i32 ---;

    /*
    * Decode a given FLIF from a file pointer
    * The filename here is used for error messages.
    * It would be helpful to pass an actual filename here, but a non-NULL dummy one can be used instead.
    */
    @(link_name="flif_decoder_decode_filepointer") decode_filepointer :: proc(decoder: Decoder, filepointer: os.Handle, filename: ^u8) -> i32 ---;

    // returns the number of frames (1 if it is not an animation)
    @(link_name="flif_decoder_num_images") num_images :: proc(decoder: Decoder) -> uint ---;
    // only relevant for animations: returns the loop count (0 = loop forever)
    @(link_name="flif_decoder_num_loops") num_loops :: proc(decoder: Decoder) -> i32 ---;
    // returns a pointer to a given frame, counting from 0 (use index=0 for still images)
    @(link_name="flif_decoder_get_image") get_image :: proc(decoder: Decoder, index: uint = 0) -> Image ---;

    @(link_name="flif_decoder_generate_preview") generate_preview :: proc(ctx: rawptr) ---;

    // release an decoder (has to be called after decoding is done, to avoid memory leaks)
    @(link_name="flif_destroy_decoder") destroy :: proc(decoder: Decoder) ---;
    // abort a decoder (can be used before decoding is completed)
    @(link_name="flif_abort_decoder") abort :: proc(decoder: Decoder) -> i32 ---;

    // decode options, all optional, can be set after decoder initialization and before actual decoding
    @(link_name="flif_decoder_set_crc_check") set_crc_check :: proc(decoder: Decoder, crc_check: i32)     ---; // default: no (0)
    @(link_name="flif_decoder_set_quality")   set_quality   :: proc(decoder: Decoder, quality: i32)       ---; // valid quality: 0-100
    @(link_name="flif_decoder_set_scale")     set_scale     :: proc(decoder: Decoder, scale: u32)         ---; // valid scales: 1,2,4,8,16,...
    @(link_name="flif_decoder_set_resize")    set_resize    :: proc(decoder: Decoder, width, height: u32) ---;
    @(link_name="flif_decoder_set_fit")       set_fit       :: proc(decoder: Decoder, width, height: u32) ---;

    // Progressive decoding: set a callback function. The callback will be called after a certain quality is reached,
    // and it should return the desired next quality that should be reached before it will be called again.
    // The qualities are expressed on a scale from 0 to 10000 (not 0 to 100!) for fine-grained control.
    // `user_data` can be NULL or a pointer to any user-defined context. The decoder doesn't care about its contents;
    // it just passes the pointer value back to the callback.
    @(link_name="flif_decoder_set_callback")               set_callback               :: proc(decoder: Decoder, callback: Callback, user_data: rawptr) ---;
    @(link_name="flif_decoder_set_first_callback_quality") set_first_callback_quality :: proc(decoder: Decoder, quality: i32)                          ---; // valid quality: 0-10000

    // Reads the header of a FLIF file and packages it as a FLIF_INFO struct.
    // May return a null pointer if the file is not in the right format.
    // The caller takes ownership of the return value and must call flif_destroy_info().
    @(link_name="flif_read_info_from_memory") read_info_from_memory :: proc(buffer: rawptr, buffer_size_bytes: uint) -> Info ---;
    // deallocator function for FLIF_INFO
    @(link_name="flif_destroy_info") destroy :: proc(info: Info) ---;

    @(link_name="flif_info_get_width")       get_width       :: proc(info: Info) -> u32  ---; // get the image width
    @(link_name="flif_info_get_height")      get_height      :: proc(info: Info) -> u32  ---; // get the image height
    @(link_name="flif_info_get_nb_channels") get_nb_channels :: proc(info: Info) -> u8   ---; // get the number of color channels
    @(link_name="flif_info_get_depth")       get_depth       :: proc(info: Info) -> u8   ---; // get the number of bits per channel
    @(link_name="flif_info_num_images")      num_images      :: proc(info: Info) -> uint ---; // get the number of animation frames
}
