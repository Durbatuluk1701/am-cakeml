(** val sig_params : coq_ASP_PARAMS **)

val sig_params = Coq_asp_paramsC "sigid" [] "0" "sigtargid"

(** val hsh_params : coq_ASP_PARAMS **)

val hsh_params = Coq_asp_paramsC "hshid" [] "0" "hshtargid"

(** val enc_params :: coq_Plc -> coq_ASP_PARAMS **)
fun enc_params q = Coq_asp_paramsC "encid" [] q "enctargid"