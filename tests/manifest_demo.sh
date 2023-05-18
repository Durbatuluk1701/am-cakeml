#!/bin/bash

if [[ "$PWD" == */am-cakeml/tests ]]; then
  repoRoot=$(dirname "$PWD")
  # Move to build folder
  cd $repoRoot/build
  # Make targets
  make demo
  make manifest_compiler

  # First let us setup the server
  tmux new-session -d -s ServerProcess '(./apps/demo/serverdemo -m ../apps/demo/server/example_Manifest.json -k ../apps/ManifestCompiler/DemoFiles/example_PrivKey)'


  # Setup tmux windows
  tmux split-window -h 'bash -i'
  tmux select-layout even-horizontal
  
  # Now run the manifest compilations
  # Sending a chain of first AM comp, run, second AM comp, run
  tmux send-keys -t 1 '(./apps/ManifestCompiler/manComp_demo -c -m ../apps/ManifestCompiler/DemoFiles/Test_FormMan.sml -l ../apps/ManifestCompiler/DemoFiles/Test_Am_Lib.sml) && (./build/COMPILED_AM -m ./concrete_manifest.json -k ../apps/ManifestCompiler/DemoFiles/example_PrivKey) && (./apps/ManifestCompiler/manComp_demo -c -m ../apps/ManifestCompiler/DemoFiles/Test_FormMan.sml -l ../apps/ManifestCompiler/DemoFiles/Test_Am_Lib2.sml) && (./build/COMPILED_AM -m ./concrete_manifest.json -k ../apps/ManifestCompiler/DemoFiles/example_PrivKey)' Enter

  tmux attach-session -d -t ServerProcess

else
  echo "You are not in the 'am-cakeml/tests' directory"
fi
