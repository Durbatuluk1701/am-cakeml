(* Depends on: SocketFFI.sml, Json.sml, JsonToCopland.sml, CoplandToJson.sml,
               CommTypes.sml, CommUtil.sml and Eval.sml *)

(* TODO: Do something with pl1 rather than assuming it is here.
   Also do something with the nameserver mapping *)
(* When things go well, this returns a JSON evidence string. When they go wrong,
   it returns a raw error message string. In the future, we may want to wrap
   said error messages in JSON as well to make it easier on the client. *)
fun evalJson s =
    let val (REQ pl1 pl2 map t ev) = JsonToCopland.jsonToRequest (strToJson s)
        val ev' = eval map ev t
        val response = RES pl2 pl1 ev'
     in jsonToStr (CoplandToJson.responseToJson response)
    end
    handle Json.ERR s1 s2 => (TextIO.print_err ("JSON error"^s1^": "^s2^"\n");
                              "Invalid JSON/Copland term")
         | USMexpn (Id n) => "Invalid USM id: "^(natToString n)^"\n"
         | KIMexpn (Id n) => "Invalid KIM id: "^(natToString n)^"\n"


fun respondToMsg client = Socket.output client (evalJson (Socket.inputAll client))

fun handleIncoming listener =
    let val client = Socket.accept listener
     in respondToMsg client;
        Socket.close client
    end
    handle Socket.Err       => TextIO.print_err "Socket failure\n"
         | Socket.InvalidFD => TextIO.print_err "Invalid file descriptor\n"

(* I'm almost certain this leaks memory. *)
fun startServer port qLen =
    let fun loop f x = (f x; loop f x)
     in loop handleIncoming (Socket.listen port qLen)
    end
    handle Socket.Err => TextIO.print_err "Socket failure on listener instantiation\n"
         | _          => TextIO.print_err "Fatal: unknown error\n"

fun main () =
    let val usage = "Usage: ./server portNumber queueLength\ne.g.   ./server 50000 5\n"
     in case CommandLine.arguments ()
          of [portStr, qLenStr] => (
             case (Int.fromString portStr, Int.fromString qLenStr)
               of (Some port, Some qLen) => startServer port qLen
                | _ => TextIO.print_err usage)
           | _ => TextIO.print_err usage
    end

val _ = main ()
