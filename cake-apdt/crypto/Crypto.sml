(* No external dependencies *)

(* Safe wrappers to FFI crypto functions *)

fun hash bs =
    let
        val result = Word8Array.array 64 (Word8.fromInt 0)
    in
        #(sha512) (ByteString.toRawString bs) result;
        result
    end

fun hashStr s =
    let
        val result = Word8Array.array 64 (Word8.fromInt 0)
    in
        #(sha512) s result;
        result
    end
