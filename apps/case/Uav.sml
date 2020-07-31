(* Depends on util, copland, dataports, and timer *)

(* Config - ideally these things would be loaded in separately, either in a configuration file at 
       compile time, or read from a file at runtime *)
val pub = (ByteString.toRawString o ByteString.fromHexString) "490E2422528F14AC6A48DDB9D72CB30B8345AF2E939003BC7A33A6057F2FFB0101000000000000002DD0B7F53A560000A049D882A37F00000000000000000000"

val goldenHashes = 
    let val hash_gs_step2 = "64AF5216C5B466442C1EBF41F0B7F370677366CFCCEACCAA73E6D4C45A6075C34EB232F9F1254F0F434CDD8B72C154098A2C0A013032E0C58FB39B38647EA54D"
        val hash_gs_threat_3A1 = "A97CBC121B87F815625C48DE3D3C40AFB9587BE46D7B13BF19B82299ED9DBCC8F62C1506F637319A25410155E314D8B4D26583B58D2A0478E57CAE2BDA9AA301"
        val hash_gs_threat_3A2 = "451FA7D5E92F20956049596199A3F68142BCA335A276DD85C5D44B3E81EAE34A7E19177DBF8BB4E3AB1711E4730741FE3D251B91E96F904570154417A4EEC2CB"
     in [hash_gs_step2, hash_gs_threat_3A1, hash_gs_threat_3A2]
    end
(* End of config.  *)

(* loop : (() -> 'a) -> 'b *)
fun loop io = (io (); loop io)

(* when : bool -> ('a -> ()) -> 'a -> () *)
fun when b f x = if b then f x else ()

val idToBytes =
    let fun rightFourChars str =
        let val strSize = String.size str
         in case Int.compare strSize 4
            of Greater => String.extract str (strSize - 5) None
             | Equal   => str
             | Less    => rightFourChars ("0" ^ str)
         end
      in rightFourChars o Int.toString
    end


(* Truncates or appends a sequence of b *)
fun bsToLen len b bs =
    let val oldLen = ByteString.length bs
     in case Int.compare oldLen len
        of Greater => ByteString.fromRawString (String.substring (ByteString.toRawString bs) 0 len)
         | Equal   => bs
         | Less    => ByteString.append bs (Word8Array.array (len - oldLen) b)
    end

(* addToWhitelist : id option -> () *)
(* Right now, this just writes over the first id, since we only have one groundstation *)
fun addToWhitelist idOpt =
    let val id_list = case idOpt
            of Some id => idToBytes id
             | None    => "0"
        val zero = Word8.fromInt 48 (* ascii '0' char *)
        val content = bsToLen 12 zero (ByteString.fromRawString id_list)
     in writeDataportBS "/dev/uio4" content (* TODO: take dataport name as a commandline argument *)
    end

(* pulse : int -> ('a -> 'b) -> 'a -> 'c *)
(* Takes a frequency (in microseconds), a function, and that function's argument.
   Repeatedly calls the function with the argument, on intervals defined by the
   frequency. *)
fun pulse freq f x =
    let val next = Ref (timestamp () + freq)
        fun spinUntil c = if c () then () else spinUntil c
     in loop (fn () => (
            f x;
            spinUntil (fn () => timestamp () >= !next);
            next := !next + freq
        ))
    end

(* parseEv : string -> ev *)
val parseEv =
    let fun strToJson str = List.hd (fst (Json.parse ([], str)))
     in jsonToEv o strToJson
    end

(* appraise : ByteString.bs -> ev -> bool *)
fun appraise nonce ev = case ev of
      G evSign (U (Id (S O)) args evHash (N i evNonce Mt)) =>
          ByteString.deepEq evNonce nonce andalso 
          List.exists (op = (ByteString.toHexString evHash)) goldenHashes andalso 
          Option.valOf (verifySig ev pub)
    | _ => False

(* attest : Socket.fd -> id -> () *)
fun attest gs id =
    let val nonce = genNonce ()
        val _ = Socket.output gs (ByteString.toRawString nonce)
        val ev = parseEv (Socket.inputAll gs)
        val spin = loop o const
     in if appraise nonce ev
          then addToWhitelist (Some id)
          else (addToWhitelist None; spin ())
    end

(* main : () -> () *)
fun main () =
    let val listener = Socket.listen 5000 5
        val gs  = Socket.accept listener
        val msg = Socket.inputAll gs
        val id  = Option.valOf (Int.fromString msg) (* For now, we assume the initial message is just the id *)
     in loop (fn () => attest gs id)
    end
    handle Socket.Err _ => TextIO.print_err "Socket error\n"
         | DataportErr  => TextIO.print_err "Dataport error\n"
         | Json.ERR _ _ => TextIO.print_err "Json error\n"
         | _            => TextIO.print_err "Fatal: unknown error\n"
val () = main ()