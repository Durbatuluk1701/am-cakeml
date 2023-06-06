(* Depends on: util, copland, am/Measurements, am/ServerAm *)

fun print_json_man_id (m:coq_Manifest) =
    let val _ = print ("\n" ^ (Json.stringify (ManifestJsonConfig.encode_Manifest m)) ^ "\n") in
    m
    end

fun print_json_man_list (ls: coq_Manifest list) =
    let val _ = List.map print_json_man_id ls
    in
      ()
    end

(*  
  Extracted helper function used in print_json_man_list_verbose below:

  demo_man_gen_run :: coq_Term -> coq_Plc -> coq_Manifest list 
      demo_man_gen_run is a function extracted from Coq that uses the manifest generator to transform 
      its inputs (a copland phrase and top-level place) to a list of formal manifests 
      (one for each place mentioned in the phrase).
*)

fun print_json_man_list_verbose (ts:coq_Term list) (p:coq_Plc) = 
  let (* val _ = print ("\nFormal Manifests generated from phrase: \n\n'" ^ (termToString t) ^ "'\n\nat top-level place: \n'" ^ p ^ "': \n") *)
      val demo_man_list : coq_Manifest list = demo_man_gen_run ts p 
      val _ = ManifestJsonConfig.write_FormalManifestList demo_man_list
  in
    (print_json_man_list demo_man_list) : unit
  end
  handle ManifestJsonConfig.Excn e => TextIOExtra.printLn e


val _ = print_json_man_list_verbose [cert_cache_p1] coq_P1 

val _ = print "\n\n\n\n"
val _ = print_json_man_list_verbose [cert_cache_p0] coq_P0
(* [cert_style, (ssl_sig_parameterized coq_P0)] *)


(* NOTE: Hardcoding of source place is here now *)
val formal_manifest = 
  (Build_Manifest 
    "0" 
    [ssl_sig_aspid] 
    ["0", "1", "2"]
    ["0", "1", "2"]
    True
  ) : coq_Manifest

val aspMapping = (mapC_from_pairList []) : ((coq_ASP_ID, coq_CakeML_ASPCallback) coq_MapC)


(** val do_asp : coq_ASP_Address -> coq_ASP_PARAMS -> coq_RawEv -> coq_BS **)
fun do_asp asp_server_addr ps e =
    let val _ = print ("Running ASP with params: \n" ^ (aspParamsToString ps) ^ "\n")
        val res = 
            case ps of Coq_asp_paramsC aspid args tpl tid =>
              case (aspid = cal_ak_aspid) of    
                  True => cal_ak_asp_stub ps e              
                | _ => 
                  case (aspid = get_data_aspid) of
                      True => get_data_asp_stub ps e                
                    | _ =>
                      case (aspid = tpm_sig_aspid) of
                          True => tpm_sig_asp_stub ps e
                        | _ =>
                          case (aspid = ssl_enc_aspid) of
                              True => ssl_enc_asp_stub ps e                  
                            | _ =>
                              case (aspid = pub_bc_aspid) of
                                  True => pub_bc_asp_stub ps e
                                | _ => 
                                  case (aspid = store_clientData_aspid) of
                                      True => store_clientData_asp_stub ps e
                                    | _ => 
                                      case (aspid = ssl_sig_aspid) of
                                          True => ssl_sig_asp_stub ps e
                                        | _ => 
                                          case (aspid = kim_meas_aspid) of
                                              True => kim_meas_asp_stub ps e
                                            | _ =>                     
                                              (print ("Matched OTHER aspid:  " ^ aspid ^ "\n");
                                                raise (Exception ("TODO: Dispatch this request to ASP server at '" ^ asp_server_addr ^ "'\n")))
    in
        res
    end

val aspServer_cb = (fn aspServerAddr => fn aspParams => fn plc => fn bs => fn rawEv => do_asp aspServerAddr aspParams rawEv) : (coq_ASP_Address -> coq_CakeML_ASPCallback)

val pubKeyServer_cb = (fn _ => fn _ => BString.unshow "OUTPUT_PUBKEY") :  (coq_ASP_Address -> coq_CakeML_PubKeyCallback)

val plcServer_cb = (fn _ => fn _ => "OUTPUT_UUID") : (coq_ASP_Address ->  coq_CakeML_PlcCallback)

val uuidServer_cb = (fn _ => fn _ => "OUTPUT_PLC") : (coq_ASP_Address -> coq_CakeML_uuidCallback)

val client_am_library = 
  (Build_AM_Library 
    aspServer_cb pubKeyServer_cb plcServer_cb uuidServer_cb
    
    "ASP_SERVER:5000" "PubKeyServer:5000" "PlcServer:5000" "UUIDServer:5000"

    aspMapping
    (mapD_from_pairList [("0", "localhost:5000"),("1", "localhost:5001"),("2", "localhost:5002")])

    (mapD_from_pairList [("0", (BString.unshow "3082010a0282010100c822fb2b7842e61fa6a779a48f2164793e21d640687146b48ac4e977a4a69f90383c94f3ea5e5336052b728f0a83151603edef890b2a6099376ae87a384a6b236ed51c7f19d94c8b4acb9b00de6cb1c6fc40ff9fec7967ebdbc48cd9b15103411a3b8978d93e59988a7baa21dd3e6fa220359e228f847b81be77bf2467bea40496135a8d06a42c3416bffec3646c8fda7eee19a74275fa2b21bfaa5c8b0dc8e82511b2d8b9a7b760b1d0ae0be03cd98615f3e6c2bc51b1ab11f5b87aad9b44264a2470f26a3a55e4dbd1fa6ea52e66093b4a3eae73bcd7237f07b1ea394a9f893b32d6da15a46f5d7e77c5a6b12ebf41cc7743f4cc241266e58566645dfbbd210203010001")),("1", (BString.unshow "3082010a0282010100c822fb2b7842e61fa6a779a48f2164793e21d640687146b48ac4e977a4a69f90383c94f3ea5e5336052b728f0a83151603edef890b2a6099376ae87a384a6b236ed51c7f19d94c8b4acb9b00de6cb1c6fc40ff9fec7967ebdbc48cd9b15103411a3b8978d93e59988a7baa21dd3e6fa220359e228f847b81be77bf2467bea40496135a8d06a42c3416bffec3646c8fda7eee19a74275fa2b21bfaa5c8b0dc8e82511b2d8b9a7b760b1d0ae0be03cd98615f3e6c2bc51b1ab11f5b87aad9b44264a2470f26a3a55e4dbd1fa6ea52e66093b4a3eae73bcd7237f07b1ea394a9f893b32d6da15a46f5d7e77c5a6b12ebf41cc7743f4cc241266e58566645dfbbd210203010001")), ("2", (BString.unshow "3082010a0282010100c822fb2b7842e61fa6a779a48f2164793e21d640687146b48ac4e977a4a69f90383c94f3ea5e5336052b728f0a83151603edef890b2a6099376ae87a384a6b236ed51c7f19d94c8b4acb9b00de6cb1c6fc40ff9fec7967ebdbc48cd9b15103411a3b8978d93e59988a7baa21dd3e6fa220359e228f847b81be77bf2467bea40496135a8d06a42c3416bffec3646c8fda7eee19a74275fa2b21bfaa5c8b0dc8e82511b2d8b9a7b760b1d0ae0be03cd98615f3e6c2bc51b1ab11f5b87aad9b44264a2470f26a3a55e4dbd1fa6ea52e66093b4a3eae73bcd7237f07b1ea394a9f893b32d6da15a46f5d7e77c5a6b12ebf41cc7743f4cc241266e58566645dfbbd210203010001"))])
    ) : coq_AM_Library
(*
val kim_meas = Coq_asp (ASPC ALL EXTD (Coq_asp_paramsC kim_meas_aspid [] dest_plc
    kim_meas_targid))
*)

fun main () =
    let val authb = True
        val auth_phrase = ssl_sig_parameterized coq_P0 (* TODO: fix this hardcoding *)
        val nonceB = True
        val appraiseB = True
        val (concreteMan, privKey, _) = ManifestJsonConfig.retrieve_CLI_args () 
        val (concrete, privKey, aspDisp, plcDisp, pubKeyDisp, uuidDisp) = ManifestUtils.setup_and_get_AM_config formal_manifest client_am_library concreteMan privKey auth_phrase
        val (Build_ConcreteManifest plc plcMap pubKeyMap aspServer_addr pubKeyServer_addr plcServer_addr uuidServer_addr) = concrete
        val main_phrase = (kim_meas dest_plc kim_meas_targid)
        (* Retrieving implicit self place from manifest here *)
        val my_plc = ManifestUtils.get_myPlc()
        (* NOTE: The dest plc is hardcoded here! *)
        val _ = TextIO.print ("Client Launched!\nLoaded following implicit place from Manifest: '" ^ my_plc ^ "'\n\n")
        val am_comp' = (am_sendReq_dispatch (Some auth_phrase) nonceB main_phrase my_plc dest_plc appraiseB plcDisp) 
        val am_comp = run_am_app_comp am_comp' empty_am_result in
        print ( ("\n\nClient Result:\n" ^ am_result_ToString (am_comp))  ^ "\n\n")
        (* print ( (evidenceCToString (run_am_app_comp am_comp empty_am_result)
          ) ^ "\n\n") *)
    end
    handle Exception e => TextIO.print_err e 
          | ManifestUtils.Excn e => TextIO.print_err ("ManifestUtils Error: " ^ e)
          | ManifestJsonConfig.Excn e => TextIO.print_err ("ManifestUtils Error: " ^ e)
          | Word8Extra.InvalidHex => TextIO.print_err "BSTRING UNSHOW ERROR"

val _ = main ()
