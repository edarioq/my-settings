#!/bin/bash

echo "Hello " $USER
echo "-- I am HEWELO, I am Whole --"
echo "\n"

EDARIOQ='edarioq'
AFFINITY_FRONTEND='affinity-frontend'
AFFINITY_STUDIOS='affinity-studios'
MY_SETTINGS='my-settings'


echo "Choose project:"
echo "(1)" $EDARIOQ
echo "(2)" $AFFINITY_FRONTEND
echo "(3)" $AFFINITY_STUDIOS
echo "(4)" $MY_SETTINGS

read PROJECT

run_tmux() {
  tmux new -d -s Code
  tmux new -d -s Git
  tmux a -t Code
}

if [ $PROJECT -eq 1 ]
then
  cd ~/development/$EDARIOQ
  run_tmux
  exec zsh
elif [ $PROJECT -eq 2 ]
then
  cd ~/development/$AFFINITY_FRONTEND
  run_tmux
  exec zsh
elif [ $PROJECT -eq 3 ]
then
  cd ~/development/$AFFINITY_STUDIOS
  run_tmux
  exec zsh
elif [ $PROJECT -eq 4 ]
then
  cd ~/development/$MY_SETTINGS
  run_tmux
  exec zsh
fi
