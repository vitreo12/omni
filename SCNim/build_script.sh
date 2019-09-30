#!/bin/bash

#-e default value
if [[ "$OSTYPE" == "darwin"* ]]; then  
  SC_EXTENSIONS_PATH=~/Library/Application\ Support/SuperCollider/Extensions
elif [[ "$OSTYPE" == "linux-gnu" ]]; then 
  SC_EXTENSIONS_PATH=~/.local/share/SuperCollider/Extensions
fi

#-a default value
BUILD_MARCH=native

#If any command fails, exit
set -e

#Path to folder where this bash script is
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#SC folder path (hardcoded in)
if [[ "$OSTYPE" == "darwin"* ]]; then
  SC_PATH=/Users/francescocameli/SuperCollider
elif [[ "$OSTYPE" == "linux-gnu" ]]; then 
  SC_PATH=~/Sources/SuperCollider-3.10.3
fi
                                        
#-e argument
SC_EXTENSIONS_PATH="${SC_EXTENSIONS_PATH/#\~/$HOME}"   #expand tilde, if there is one
SC_EXTENSIONS_PATH=${SC_EXTENSIONS_PATH%/}             #remove trailing slash, if there is one

#Create build dir, deleting a previous one if it was there.
rm -rf build; mkdir -p build
cd build

#Actually make
cmake -DSC_PATH=$SC_PATH -DCMAKE_BUILD_TYPE=Release -DBUILD_MARCH=$BUILD_MARCH ..
make 

mkdir -p NimCollider

echo "Copying files over..."

if [[ "$OSTYPE" == "darwin"* ]]; then                     
  cp Nim.scx ./NimCollider                                                      
elif [[ "$OSTYPE" == "linux-gnu" ]]; then 
  cp Nim.so ./NimCollider                                                       
fi          

rsync --update ../Nim.sc ./NimCollider 
rsync --update ../Sine.nim ./NimCollider

if [[ "$OSTYPE" == "darwin"* ]]; then                                      
  rsync --update ../libSine.dylib ./NimCollider
elif [[ "$OSTYPE" == "linux-gnu" ]]; then 
  rsync --update ../libSine.so ./NimCollider
fi

#Copy the whole build/JuliaCollider folder over to SC's User Extension directory
rsync -r --links --update ./NimCollider "$SC_EXTENSIONS_PATH"

echo "Done!"