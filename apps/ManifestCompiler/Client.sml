(* Depends on: util, copland, am/Measurements, am/ServerAm *)

val kim_meas = Coq_asp (ASPC ALL EXTD (Coq_asp_paramsC kim_meas_aspid [] dest_plc
    kim_meas_targid))

fun main () =
    let val authb = True
        val concreteMan = ManifestJsonConfig.retrieve_concrete_manifest () 
        val (concrete, aspDisp, plcDisp, pubKeyDisp, uuidDisp) = ManifestUtils.setup_and_get_AM_config formal_manifest client_am_library concreteMan
        val (Build_ConcreteManifest plc uuid privateKey plcMap pubKeyMap aspServer_addr pubKeyServer_addr plcServer_addr uuidServer_addr) = concrete
        val main_phrase = kim_meas (*demo_phrase3*)
        (* Retrieving implicit self place from manifest here *)
        val my_plc = ManifestUtils.get_myPlc()
        (* NOTE: The dest plc is hardcoded here! *)
        val _ = TextIO.print ("Client Launched!\nLoaded following implicit place from Manifest: '" ^ my_plc ^ "'\n\n")
        val _ = TextIO.print ("Loaded following implicit UUID from Manifest: '" ^ uuid ^ "'\n\n")
        val am_comp = (am_sendReq_dispatch authb main_phrase my_plc dest_plc aspDisp pubKeyDisp plcDisp) 
    in
        print ( (evidenceCToString (run_am_app_comp am_comp Coq_mtc_app)
          ) ^ "\n\n")
    end
    handle Exception e => TextIO.print_err e 
          | ManifestUtils.Excn e => TextIO.print_err ("ManifestUtils Error: " ^ e)
          | ManifestJsonConfig.Excn e => TextIO.print_err ("ManifestUtils Error: " ^ e)
          | Word8Extra.InvalidHex => TextIO.print_err "BSTRING UNSHOW ERROR"

val _ = main ()
