structure ManifestJsonConfig = struct
  exception Excn string

  type plc_t                  = coq_Plc
  type uuid_t                 = coq_UUID
  type privateKey_t           = coq_PrivateKey
  type pubKey_t               = coq_PublicKey
  type plcMap_t               = ((plc_t, uuid_t) map)
  type pubKeyMap_t            = ((plc_t, pubKey_t) map)
  type aspServer_t            = coq_ASP_Address
  type pubKeyServer_t         = coq_ASP_Address
  type plcServer_t            = coq_ASP_Address
  type uuidServer_t           = coq_ASP_Address

  (* just a wrapper for bstring.unshow to hoist it into option type 
      : string -> BString.bstring option *)
  fun bstring_cast (s : string) = Some (BString.unshow s)

  (* A wrapper around strings to hoist them into option types 
      : string -> string option *)
  fun string_cast (s : string) = Some s

  (* Attempts to parse out a value from Json and cast it
      : Json.json -> string -> (string -> ('A option)) -> 'A *)
  fun parse_and_cast (j : Json.json) (key : string) castFn =
    case (Json.lookup key j) of
      None => raise (Excn ("Could not find '" ^ key ^ "' in JSON"))
      | Some pval => 
          case (Json.toString pval) of
              None => raise (Excn ("'" ^ key ^ "' was found, but is not a string"))
              | Some sval =>
                  case (castFn sval) of
                      None => raise (Excn ("'" ^ key ^ "' found, but could not be cast"))
                      | Some pval' => pval'

  (* Encodes casts a value and encodes it into Json 
      : 'A -> ('A -> string) -> Json.json *)
  fun cast_and_encode v castFn = Json.fromString (castFn v)

  (* Parses a json file into its JSON representation 
      : string -> Json.json *)
  fun parseJsonFile (file : string) =
      Result.mapErr (op ^ "Parsing error: ") (Json.parse (TextIOExtra.readFile file))
      handle 
          TextIO.BadFileName => Err "Bad file name"
          | TextIO.InvalidFD   => Err "Invalid file descriptor"
          (* TODO: Handle JSON parsing exceptions *)

  (* Attempts to extract a plcMap from a Json structure of a concrete manifest
    : Json.json -> plcMap_t *)
  fun extract_plcMap (j : Json.json) =
      let val gatherPlcs = case (Json.lookup "plcMap" j) of
                              None => raise (Excn ("Could not find 'plcMap' field in JSON"))
                              | Some v => v
          val jsonPlcPairList = case (Json.toList gatherPlcs) of
                          None => raise (Excn ("Could not convert Json into a list of json pairs")) 
                          | Some m => m (* (json list) *)
          (* Now we want to convert each element in the plcPairList to 
            a pair representation
              (json) -> (plc_t * uuid_t) *)
          fun converter (j : Json.json) =
              (let val jsonSubList = (case (Json.toList j) of
                                        None => raise (Excn "Could not convert a JSON place mapping to a list")
                                        | Some v => v)
                  val plc = (case (Json.toString (List.nth jsonSubList 0)) of
                              None => raise (Excn "Could not convert plc in mapping to a string")
                              | Some v => v)
                  val uuid = (case (Json.toString (List.nth jsonSubList 1)) of
                              None => raise (Excn "Could not convert uuid in mapping to a string")
                              | Some v => v)
              in
                (plc, uuid)
              end) : (plc_t * uuid_t)
          val plcPairList = (List.map converter jsonPlcPairList) : ((plc_t * uuid_t) list)
      in
        (Map.fromList String.compare plcPairList)
      end

  (* Encodes the plc Map as Json.json
    : plcMap_t -> Json.json *)
  fun encode_plcMap (p : plcMap_t) =
      let val unpackedMap = Map.toAscList p (* (plc_t * uuid_t) list *)
          fun encoder ((p, u) : (plc_t * uuid_t)) = 
            (* Converts the pair to a Json list representing the pair *)
            (Json.fromList [Json.fromString p, Json.fromString u])
          val newList = (List.map encoder unpackedMap)
      in
        (Json.fromList newList)
      end

  (* Attempts to extract a pubKeyMap from a Json structure of a concrete manifest
    : Json.json -> pubKeyMap_t *)
  fun extract_pubKeyMap (j : Json.json) =
      let val gatherPlcs = case (Json.lookup "pubKeyMap" j) of
                              None => raise (Excn ("Could not find 'pubKeyMap' field in JSON"))
                              | Some v => v
          val jsonPlcPairList = case (Json.toList gatherPlcs) of
                          None => raise (Excn ("Could not convert Json into a list of json pairs")) 
                          | Some m => m (* (json list) *)
          (* Now we want to convert each element in the plcPairList to 
            a pair representation
              (json) -> (plc_t * pubKey_t) *)
          fun converter (j : Json.json) =
              (let val jsonSubList = (case (Json.toList j) of
                                        None => raise (Excn "Could not convert a JSON pubkey mapping to a list")
                                        | Some v => v)
                  val plc = (case (Json.toString (List.nth jsonSubList 0)) of
                              None => raise (Excn "Could not convert plc in mapping to a string")
                              | Some v => v)
                  val pubKey = (case (Json.toString (List.nth jsonSubList 1)) of
                              None => raise (Excn "Could not convert pubkey in mapping to a string")
                              | Some v => v)
                  val binPubKey = BString.unshow pubKey
              in
                (plc, binPubKey)
              end) : (plc_t * pubKey_t)
          val plcPairList = (List.map converter jsonPlcPairList) : ((plc_t * pubKey_t) list)
      in
        (Map.fromList String.compare plcPairList)
      end


  (* Encodes the pubKey Map as Json.json
    : pubKeyMap_t -> Json.json *)
  fun encode_pubKeyMap (p : pubKeyMap_t) =
      let val unpackedMap = Map.toAscList p (* (plc_t * pubKey_t) list *)
          fun encoder ((p, pk) : (plc_t * pubKey_t)) = 
            (* Converts the pair to a Json list representing the pair *)
            (Json.fromList [Json.fromString p, Json.fromString (BString.show pk)])
          val newList = (List.map encoder unpackedMap)
      in
        (Json.fromList newList)
      end

  (* Parses Json representation of a concrete manifest into a coq_ConcreteManifest 
    : Json.json -> coq_ConcreteManifest *)
  fun extract_ConcreteManifest (j : Json.json) =
    let val plc = (parse_and_cast j "plc" string_cast)
        val uuid = (parse_and_cast j "uuid" string_cast)
        val privateKey = (parse_and_cast j "privateKey" bstring_cast)
        val plcMap = extract_plcMap j
        val pubKeyMap = extract_pubKeyMap j
        val aspServer_addr = (parse_and_cast j "aspServer" string_cast)
        val pubKeyServer_addr = (parse_and_cast j "pubKeyServer" string_cast)
        val plcServer_addr = (parse_and_cast j "plcServer" string_cast)
        val uuidServer_addr = (parse_and_cast j "uuidServer" string_cast)
    in
      (Build_ConcreteManifest plc uuid privateKey plcMap pubKeyMap
        aspServer_addr pubKeyServer_addr plcServer_addr uuidServer_addr)
    end

  (* Encodes a coq_ConcreteManifest into its JSON representation 
    : coq_ConcreteManifest -> Json.json *)
  fun encode_ConcreteManifest (cm : coq_ConcreteManifest) =
    let val (Build_ConcreteManifest plc uuid privateKey plcMap pubKeyMap aspServer_addr pubKeyServer_addr plcServer_addr uuidServer_addr) = cm
        val cmJson = [
          ("plc", Json.fromString plc),
          ("uuid", Json.fromString uuid),
          ("privateKey", (cast_and_encode privateKey BString.show)),
          ("plcMap", (encode_plcMap plcMap)),
          ("pubKeyMap", (encode_pubKeyMap pubKeyMap)),
          ("aspServer", Json.fromString aspServer_addr),
          ("pubKeyServer", Json.fromString pubKeyServer_addr),
          ("plcServer", Json.fromString plcServer_addr),
          ("uuidServer", Json.fromString uuidServer_addr)
        ]
    in
      Json.fromMap (Map.fromList String.compare cmJson)
    end


  (* Retrieves the concrete manifest based upon Command Line arguments
    : () -> coq_ConcreteManifest *)
  fun retrieve_concrete_manifest _ =
    let val name = CommandLine.name ()
        val usage = ("Usage: " ^ name ^ " -m <concreteManifestFile>.json\n" ^
                      "e.g.\t" ^ name ^ " -m concMan.json\n")
        val jsonFile = (case CommandLine.arguments () of 
                          argList => (
                            let val manInd = ListExtra.find_index argList "-m"
                            in
                              if (manInd = ~1)
                              then raise (Excn ("Invalid Arguments\n" ^ usage))
                              else (
                                let val fileName = List.nth argList (manInd + 1)
                                in
                                  case (parseJsonFile fileName) of
                                    Err e => raise (Excn ("Could not parse JSON file: " ^ e ^ "\n"))
                                    | Ok j => j
                                end
                              )
                            end
                          ))
        val cm = extract_ConcreteManifest jsonFile
    in
      cm
    end
end



structure ManifestUtils = struct
  exception Excn string

  type Partial_ASP_CB     = coq_ConcreteManifest -> coq_CakeML_ASPCallback
  type Partial_Plc_CB     = coq_ConcreteManifest -> coq_CakeML_PlcCallback
  type Partial_PubKey_CB  = coq_ConcreteManifest -> coq_CakeML_PubKeyCallback
  type Partial_UUID_CB    = coq_ConcreteManifest -> coq_CakeML_uuidCallback

  type AM_Config = (coq_ConcreteManifest * 
      (coq_CakeML_ASPCallback) * 
      (coq_CakeML_PlcCallback) * 
      (coq_CakeML_PubKeyCallback) * 
      (coq_CakeML_uuidCallback))

  val local_formal_manifest = Ref (Err "Formal Manifest not set") : ((coq_Manifest, string) result) ref

  val local_concreteManifest = Ref (Err "Concrete Manifest not set") : ((coq_ConcreteManifest, string) result) ref

  val local_aspCb = Ref (Err "ASP Callback not set") : ((Partial_ASP_CB, string) result) ref

  val local_plcCb = Ref (Err "Plc Callback not set") : ((Partial_Plc_CB, string) result) ref

  val local_pubKeyCb = Ref (Err "PubKey Callback not set") : ((Partial_PubKey_CB, string) result) ref

  val local_uuidCb = Ref (Err "UUID callback not set") : ((Partial_UUID_CB, string) result) ref

  (* Setups up the relevant information and compiles the manifest
      : coq_Manifest -> coq_AM_Library -> () *)
  fun setup_AM_config (fm : coq_Manifest) (al : coq_AM_Library) =
    (case (manifest_compiler fm al) of
      Coq_pair (Coq_pair (Coq_pair (Coq_pair concrete aspDisp) plcDisp) pubKeyDisp) uuidDisp =>
        let val _ = local_formal_manifest := Ok fm
            val _ = local_concreteManifest := Ok concrete
            val _ = local_aspCb := Ok aspDisp
            val _ = local_plcCb := Ok plcDisp
            val _ = local_pubKeyCb := Ok pubKeyDisp
            val _ = local_uuidCb := Ok uuidDisp
        in
          ()
        end) : unit

  (* Retrieves the formal manifest, or exception if not configured 
    : _ -> coq_Manifest *)
  fun get_FormalManifest _ =
    (case (!local_formal_manifest) of
      (Ok v) => v
      | Err e => raise Excn e) : coq_Manifest
    
  (* Retrieves the concrete manifest, or exception if not configured 
    : _ -> coq_ConcreteManifest *)
  fun get_ConcreteManifest _ =
    (case (!local_concreteManifest) of
      (Ok v) => v
      | Err e => raise Excn e) : coq_ConcreteManifest

  (* Sets the concrete manifest, should not throw
    : coq_ConcreteManifest -> () *)
  fun set_ConcreteManifest (c : coq_ConcreteManifest) =
    let val _ = local_concreteManifest := Ok c
    in 
      ()
    end

  (* Retrieves the plc corresponding to this processes Manifest/AM_Config
      throws an exception if configuration not completed
    : _ -> coq_Plc *)
  fun get_myPlc _ = 
    (let val (Build_ConcreteManifest my_plc _ _ _ _ _ _ _ _) = get_ConcreteManifest() in
      my_plc
    end) : coq_Plc

  
  (* Retrieves the uuid corresponding to this processes Manifest/AM_Config
      throws an exception if configuration not completed
    : _ -> coq_UUID *)
  fun get_myUUID _ = 
    (let val (Build_ConcreteManifest _ my_uuid _ _ _ _ _ _ _) = get_ConcreteManifest() in
      my_uuid
    end) : coq_UUID

  (* Retrieves the private key corresponding to this processes Manifest/AM_Config
      throws an exception if configuration not completed
    : _ -> coq_PrivateKey *)
  fun get_myPrivateKey _ = 
    (let val (Build_ConcreteManifest _ _ my_privKey _ _ _ _ _ _) = get_ConcreteManifest() in
      my_privKey
    end) : coq_PrivateKey

  (* Retrieves the asp callback, or exception if not configured 
    : _ -> coq_CakeML_ASPCallback *)
  fun get_ASPCallback _ =
    (let val cm = get_ConcreteManifest() 
    in
      case (!local_aspCb) of
      (Ok v) => (v cm)
      | Err e => raise Excn e
    end) : coq_CakeML_ASPCallback

  (* Retrieves the plc callback, or exception if not configured 
    : _ -> coq_CakeML_PlcCallback *)
  fun get_PlcCallback _ =
    (let val cm = get_ConcreteManifest()
    in
      case (!local_plcCb) of
      (Ok v) => (v cm)
      | Err e => raise Excn e
    end) : coq_CakeML_PlcCallback

  (* Retrieves the asp callback, or exception if not configured 
    : _ -> coq_CakeML_PubKeyCallback *)
  fun get_PubKeyCallback _ =
    (let val cm = get_ConcreteManifest()
    in
      case (!local_pubKeyCb) of
      (Ok v) => (v cm)
      | Err e => raise Excn e
    end) : coq_CakeML_PubKeyCallback

  (* Retrieves the asp callback, or exception if not configured 
    : _ -> coq_CakeML_uuidCallback *)
  fun get_UUIDCallback _ =
    (let val cm = get_ConcreteManifest()
    in
      case (!local_uuidCb) of
      (Ok v) => (v cm)
      | Err e => raise Excn e
    end) : coq_CakeML_uuidCallback

  (* Retrieves all AM config information, 
      if a Manifest has not be compiled yet it will throw an error
    : _ -> AM_Config *)
  fun get_AM_config _ =
    (let val cm = get_ConcreteManifest()
        val aspCb = get_ASPCallback()
        val plcCb = get_PlcCallback()
        val pubKeyCb = get_PubKeyCallback()
        val uuidCb = get_UUIDCallback()
    in
      (cm, aspCb, plcCb, pubKeyCb, uuidCb)
    end) : AM_Config

  (* Directly combines setup and get steps in one function call. 
      Additionally, we must provide a "fresh" Concrete Manifest to 
      use for manifest operations
    : coq_Manifest -> coq_AM_Library -> AM_Config *)
  fun setup_and_get_AM_config (fm : coq_Manifest) (al : coq_AM_Library) (cm : coq_ConcreteManifest) =
    (let val _ = setup_AM_config fm al
         val _ = set_ConcreteManifest cm in
      get_AM_config()
    end) : AM_Config
end