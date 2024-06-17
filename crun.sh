#!/bin/bash

MAX_TEMPS=5
WORKING_DIR=$(dirname -- "$(readlink -f -- "$0")")/crun/

if [ ! -d "$WORKING_DIR" ]; then
    mkdir "$WORKING_DIR"
fi

help() {
    echo "Usage: ./crun <exec-command> [<-h/-v/-c/-p>]"
    echo "Options:"
    echo "    -h,                  Show this help."
    echo "    -v,                  View all temporary files."
    echo "    -c,                  Clear all the temporary files."
    echo "    -p,                  Execute a previous temporary file [using the number]."
    echo ""
    echo "Examples:"
    echo "    ./crun mine.sh"
    echo "    ./crun -v"
    echo "    ./crun python -p 2"
    echo ""
}

if [ -z "$1" ]; then
    help
    echo "Please input an execution command."
    exit 1
fi

if [[ -z $1 ]]; then
    echo "That command can not be found."
    exit 1

elif [[ $1 == *".sh"* ]]; then
    if [ -f "$WORKING_DIR/$1" ]; then
        cmd=$WORKING_DIR/$1
        ((OPTIND++))
    else
        echo "That command can not be found."
        exit 1
    fi

elif [ -x "$(command -v $1)" ]; then
    cmd=$1
    ((OPTIND++))
else
    echo "That command can not be found."
    exit 1
fi

while getopts ":hvcp:" flag; do
    case "${flag}" in
        h)
            help
            exit 0
        ;;
        v)
            i=0
            for filename in $WORKING_DIR/*; do
                if [[ $filename == *"temp"* ]]; then
                    echo "$(basename "$filename")"
                    ((i++))
                fi
            done
            echo "Total files found: $i"
            exit 0
        ;;
        c)
            for ((i = 1; i < MAX_TEMPS; i++)); do
                rm $WORKING_DIR/temp$i.crun 2> /dev/null
            done
            rm $WORKING_DIR/temp.crun 2> /dev/null
            echo "Cleared all the temporary files."
            exit 0
        ;;
        p)
            i=${OPTARG}
            if [ -f "$WORKING_DIR/temp$i.crun" ]; then
                vi $WORKING_DIR/temp$i.crun
		echo $cmd
                $cmd $WORKING_DIR/temp$i.crun
                exit 0
            else
                echo "That temporary file does not exist."
                exit 1
            fi
        ;;
        :)
            echo "Option -$OPTARG requires an argument"
        ;;
        \?)
            echo "Invalid option: -$OPTARG"
            exit 1
        ;;
    esac
done

file=temp0.crun
for ((i = 1; i < MAX_TEMPS; i++)); do
    if ! [ -f "$WORKING_DIR/temp$i.crun" ]; then
        file=temp$i.crun
        break
    fi
done

if [ "$file" == "temp0.crun" ]; then
    for ((i=1; i < MAX_TEMPS; i++)); do
        rm $WORKING_DIR/temp$i.crun 2> /dev/null
    done
fi

vi $WORKING_DIR/$file
$cmd $WORKING_DIR/$file
