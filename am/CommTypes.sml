(* Depends on: util, extracted/,
   copland/Json/CoplandToJson *)

type addr = string
(* Nameserver mapping *)
(* We could map to an address/port pair, but for now we assume the port number
   is 5000 *)
(*                  plc     (keyName -> value for the keys "ip", "port", "publicKey") *)                                   
datatype requestMessage = REQ coq_Plc coq_Plc coq_Term coq_ReqAuthTok (bs list)

                              
(* To place,
   From place,
   Gathered evidence *)
datatype responseMessage = RES coq_Plc coq_Plc (bs list)
