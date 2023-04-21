(* Depends on: (TODO: dependencies?) *)

(* fun appraise_ssl_sig : 
   coq_ASP_PARAMS -> coq_Plc -> coq_BS -> coq_RawEv -> coq_BS 

   Performs openssl signature checking *)
fun appraise_ssl_sig (ps : coq_ASP_PARAMS) (p : coq_Plc) (bs : coq_BS) (ls : coq_RawEv)  =
    let
        val msg = encode_RawEv ls
        val signGood_loc = bs

        val pubkey = (ManifestUtils.get_PubKeyCallback() p) : BString.bstring
                              
        val pub_len = BString.length pubkey
        val sig_len = BString.length signGood_loc
        val msg_len = BString.length msg

                                     (*
	val pubkeyfile_dest = "src-pub.pem" (* "src-pub-temp-client.pem" *)
        val outFileHandle = TextIO.openOut pubkeyfile_dest
	val _ = print ("\nOutputting pubkey FROM blockchain TO file: " ^ pubkeyfile_dest ^ "\n")
        val _ = TextIO.output outFileHandle (BString.toString theirPubkey)
                                     *)
                                     
        val checkGood = Crypto.sigCheck pubkey signGood_loc msg (* Crypto.checkTpmSig signGood msg *)
    in
        if checkGood
        then (print ("\nSSL Sig Check PASSED\n\n");
              passed_bs)
        else (print ("\nSSL Sig Check FAILED\n\n");
              failed_bs)
    end
