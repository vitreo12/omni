 
 
#!/bin/bash

PRINT_HELP=0

NAME=Nim_PROTO

#-p default value
if [[ "$OSTYPE" == "darwin"* ]]; then
  SC_PATH=~/SuperCollider
elif [[ "$OSTYPE" == "linux-gnu" ]]; then 
  SC_PATH=~/Sources/SuperCollider
fi

#-e default value
if [[ "$OSTYPE" == "darwin"* ]]; then  
  SC_EXTENSIONS_PATH=~/Library/Application\ Support/SuperCollider/Extensions
elif [[ "$OSTYPE" == "linux-gnu" ]]; then 
  SC_EXTENSIONS_PATH=~/.local/share/SuperCollider/Extensions
fi

#-s default value
SUPERNOVA="0"

#-a default value
BUILD_MARCH=native

#Unpack -c (CORES) -e (EXTENSIONS DIR) -a (BUILD_MARCH) arguments
while getopts "p:e:a:s:h" opt; do #Note that "h" is not followed by ":", which would make it expect an argument.
  case $opt in
    p) SC_PATH="$OPTARG"
    ;;
    e) SC_EXTENSIONS_PATH="$OPTARG"
    ;;
    a) BUILD_MARCH="$OPTARG"
    ;;
    s) SUPERNOVA="$OPTARG"
    ;;
    h) PRINT_HELP=1
    ;;
    \?) PRINT_HELP=1                 #If no recognizable args, print the help 
    ;;
  esac
done

#Check if user has inputted some error stuff (like "-a -h", "-a -e", etc... which would assign -a the value -h / -e)
if [[ ${BUILD_MARCH:0:1} == '-' ]] || [[ ${SC_PATH:0:1} == '-' ]] || [[ ${SC_EXTENSIONS_PATH:0:1} == '-' ]]; then #Variable starts with "-"
  PRINT_HELP=1
fi

#Check if user is looking for help
if [ $PRINT_HELP == 1 ]; then
  echo
  echo "-------------------------------------------------------------------------------------------------"
  echo
  echo "  ${NAME}: build script help file. "
  echo
  echo "   FLAGS: "
  echo
  echo "    [-p] [default MacOS = ~/SuperCollider] " 
  echo "         [default Linux = ~/Sources/SuperCollider] :"
  echo 
  echo "         - SuperCollider's source path"
  echo
  echo "    [-e] [default MacOS = ~/Library/Application\ Support/SuperCollider/Extensions]"
  echo "         [default Linux = ~/.local/share/SuperCollider/Extensions] : "
  echo
  echo "         - Your SuperCollider's \"Platform.userExtensionDir\" or \"Platform.systemExtensionDir\"."
  echo 
  echo "    [-s] [default = 0]"
  echo
  echo "         - Build with supernova support"
  echo
  echo "    [-a] [OPTIONAL] [default = native] : "
  echo
  echo "         - Build architecture."
  echo 
  echo "-------------------------------------------------------------------------------------------------"
  echo
  exit 1
fi

#If any command fails, exit
set -e

#Path to folder where this bash script is
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#-p argument
SC_PATH="${SC_PATH/#\~/$HOME}"   #expand tilde, if there is one
SC_PATH=${SC_PATH%/}             #remove trailing slash, if there is one

if [ ! -d "$SC_PATH" ]; then
  echo "*** ERROR *** [-p] argument, '$SC_PATH', is not a valid folder. Insert your SuperCollider's source path."
  exit 1
fi
                                        
#-e argument
SC_EXTENSIONS_PATH="${SC_EXTENSIONS_PATH/#\~/$HOME}"   #expand tilde, if there is one
SC_EXTENSIONS_PATH=${SC_EXTENSIONS_PATH%/}             #remove trailing slash, if there is one

if [ ! -d "$SC_EXTENSIONS_PATH" ]; then
  echo "*** ERROR *** [-e] argument, '$SC_EXTENSIONS_PATH', is not a valid folder. Insert your SuperCollider \"Platform.userExtensionDir\"."
  exit 1
fi

#Nim compile
nim c --import:/home/francesco/Sources/NimCollider/nimcollider.nim --app:lib --gc:none --noMain:on -d:supercollider -d:release -d:danger --checks:off --assertions:off --opt:speed ${NAME}.nim

#Create lib folder and move the shared lib
rm -rf lib; mkdir -p lib
if [[ "$OSTYPE" == "darwin"* ]]; then  
    mv lib${NAME}.dylib ./lib
elif [[ "$OSTYPE" == "linux-gnu" ]]; then
    mv lib${NAME}.so ./lib
fi

#Create build dir, deleting a previous one if it was there.
rm -rf build; mkdir -p build
cd build

#cmake config
if [[ "$SUPERNOVA" == "1" ]]; then
  cmake -DSTATIC_FOLDER=$DIR -DFILENAME=$NAME -DSC_PATH=$SC_PATH -DCMAKE_BUILD_TYPE=Release -DBUILD_MARCH=$BUILD_MARCH -DSUPERNOVA=ON ..
else
  cmake -DSTATIC_FOLDER=$DIR -DFILENAME=$NAME -DSC_PATH=$SC_PATH -DCMAKE_BUILD_TYPE=Release -DBUILD_MARCH=$BUILD_MARCH ..
fi

#Actually make
make 

#Create folder
mkdir p ${NAME}

echo "Copying files over..."

#Copy binaries to folder
if [[ "$OSTYPE" == "darwin"* ]]; then                     
  cp ${NAME}.scx ./${NAME}  
  
  if [[ "$SUPERNOVA" == "1" ]]; then
    cp ${NAME}_supernova.scx ./${NAME}
  fi

elif [[ "$OSTYPE" == "linux-gnu" ]]; then 
  cp ${NAME}.so ./${NAME}  

  if [[ "$SUPERNOVA" == "1" ]]; then
    cp ${NAME}_supernova.so ./${NAME}
  fi

fi           

#Copy SC file
rsync --update ../${NAME}.sc ./${NAME} 

#Copy lib folder
rsync -r --links --update ../lib ./${NAME}

#Copy the whole build folder over to SC's User Extension directory
rsync -r --links --update ./${NAME} "$SC_EXTENSIONS_PATH"

echo "Done!"