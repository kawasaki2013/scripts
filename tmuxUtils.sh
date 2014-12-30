#!/usr/bin/env bash

function tmuxStatus {
  IFS_ORIG=$IFS
  IFS=$'\n'
  wins=($(tmux list-windows -F "#I #F"))
  IFS=$IFS_ORIG
  current=0
  noview=0
  for line in "${wins[@]}";do
    iw=$(printf "$line"|cut -d' ' -f1)
    fw=$(printf "$line"|cut -d' ' -f2)
    if [ "$fw" = "*" ];then
      current=1
    else
      current=0
    fi
    IFS_ORIG=$IFS
    IFS=$'\n'
    panes=($(tmux list-panes -t $iw -F "#D #{pane_active} #{pane_current_path}"))
    IFS=$IFS_ORIG
    first=1
    status=""
    for line in "${panes[@]}";do
      ip=$(echo "$line"|cut -d' ' -f1|sed 's/%//')
      fp=$(echo "$line"|cut -d' ' -f2)
      pp=$(echo "$line"|cut -d' ' -f3)
      if [ $first -eq 1 ];then
        first=0
      else
        status="$status#[bg=colour238] #[bg=colour008]"
      fi
      if [ $current -eq 1 ] && [ $fp -eq 1 ];then
        status="$status#[bg=colour255]"
      else
        status="$status#[bg=colour008]"
      fi
      status="$status${ip}:$(hostname -s) $(basename $pp)"
    done
    status="$status#[bg=colour236] #[bg=colour008]"
    tmux rename-window -t :$iw "${status}"
  done
}

function tmuxCreate {
  wins=($(tmux list-windows -F "#I"))
  if [ ${#wins[@]} -eq 1 ];then
    tmux new-window -d
    tmux swap-pane -s :+
  else
    tmux split-window -d -t :+.bottom
    tmux swap-pane -s :+.bottom
  fi
  tmuxStatus
}

function tmuxAlign {
  wins=($(tmux list-windows -F "#I"))
  if [ ${#wins[@]} -le 2 ];then
    return
  else
    for((i=2;i<${#wins[@]};i++));do
      panes=($(tmux list-panes -t ${wins[$i]} -F "#P"))
      for((j=0;j<${#panes[@]};j++));do
        tmux join-pane -d -s :${wins[$i]}.${panes[$j]} -t :${wins[1]}.bottom
      done
    done
  fi
  tmuxStatus
}

function tmuxSplit {
  wins=($(tmux list-windows -F "#I"))
  if [ ${#wins[@]} -eq 1 ];then
    tmux split-window -v
  else
    tmux join-pane -v -s :+.top
  fi
  tmuxStatus
}

function tmuxVSplit {
  wins=($(tmux list-windows -F "#I"))
  if [ ${#wins[@]} -eq 1 ];then
    tmux split-pane -h
  else
    tmux join-pane -h -s :+.top
  fi
  tmuxStatus
}

if [ "$1" == "status" ];then
  tmuxStatus
elif [ "$1" == "create" ];then
  tmuxCreate
elif [ "$1" == "align" ];then
  tmuxAlign
elif [ "$1" == "split" ];then
  tmuxSplit
elif [ "$1" == "vsplit" ];then
  tmuxVSplit
fi