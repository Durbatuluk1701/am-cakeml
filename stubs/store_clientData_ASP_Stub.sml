(* Stub code for ASP with asp ID:  store_clientData_aspid *)

(* store_clientData_asp_stub :: coq_ASP_PARAMS -> coq_RawEv -> coq_BS *)
fun store_clientData_asp_stub ps e =
    case ps of Coq_asp_paramsC aspid args tpl tid =>
               let val _ = (print ("\nRunning store_clientData asp here...\n"))
                   val outfile = "client_data.txt"
                   val ostream = TextIO.openOut outfile
                   val client_data = encode_RawEv e
                   val _ = TextIO.output ostream (BString.toString client_data)
                   val _ = TextIO.closeOut ostream
                                         
               in 
                   BString.empty
               end
                   
