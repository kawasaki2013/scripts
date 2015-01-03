#!/usr/bin/env bash

function tmuxStatus {
  printf "\e]2;$(hostname -s)\e\\"
}

function tmuxWindowName {
  IFS_ORIG=$IFS
  IFS=$'\n'
  wins=($(tmux list-windows -F "#I #{window_active}"))
  IFS=$IFS_ORIG
  current=0
  noview=0
  for line in "${wins[@]}";do
    iw=$(printf "$line"|cut -d' ' -f1)
    fw=$(printf "$line"|cut -d' ' -f2)
    if [ "$fw" -eq 1 ];then
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

function tmuxLeft {
  IFS_ORIG=$IFS
  IFS=$'\n'
  wins=($(tmux list-windows -F "#I #{window_active}"))
  IFS=$IFS_ORIG
  current=0
  status=""
  noview=0
  for line in "${wins[@]}";do
    iw=$(printf "$line"|cut -d' ' -f1)
    fw=$(printf "$line"|cut -d' ' -f2)
    if [ "$fw" -eq 1 ];then
      current=1
    else
      current=0
    fi
    IFS_ORIG=$IFS
    IFS=$'\n'
    panes=($(tmux list-panes -t $iw -F "#D #{pane_active} #{pane_current_path} #T"))
    IFS=$IFS_ORIG
    first=1
    for line in "${panes[@]}";do
      ip=$(echo "$line"|cut -d' ' -f1|sed 's/%//')
      fp=$(echo "$line"|cut -d' ' -f2)
      pp=$(echo "$line"|cut -d' ' -f3)
      tp=$(echo "$line"|cut -d' ' -f4)
      if [ $first -eq 1 ];then
        first=0
      else
        status="$status#[bg=colour238] #[bg=colour008]"
        noview=$((noview+30))
      fi
      if [ $current -eq 1 ] && [ $fp -eq 1 ];then
        status="$status#[bg=colour255]"
        noview=$((noview+15))
      else
        status="$status#[bg=colour008]"
        noview=$((noview+15))
      fi
      status="$status${ip}@${tp} $(basename $pp)"
      #status="$status${iw}.${ip}:#h $(basename $pp)"
      #noview=$((noview-15))
    done
    status="$status#[bg=colour000]..#[bg=colour008]"
    noview=$((noview+30))
  done
  echo -n ${status: 0: $(($(tput cols)+noview-32))}
}

function tmuxAlign {
  wins=($(tmux list-windows -F "#I"))
  if [ ${#wins[@]} -lt 2 ];then
    return
  fi
  flag=$(tmux list-windows -F "#{window_active} #I"|grep ^1|sed 's/^1 //')
  if [ "$flag" -ne 0 ];then
    tmux swap-window -t:+
  fi
  for((i=2;i<${#wins[@]};i++));do
    panes=($(tmux list-panes -t ${wins[$i]} -F "#P"))
    for((j=0;j<${#panes[@]};j++));do
      tmux join-pane -d -s :${wins[$i]}.${panes[$j]} -t :${wins[1]}.bottom
    done
  done
}

function tmuxCreate {
  wins=($(tmux list-windows -F "#I"))
  if [ ${#wins[@]} -eq 1 ];then
    tmux new-window -d
    tmux swap-pane -d -s :+
  else
    tmux split-window -d -t :+.bottom
    tmux swap-pane -s :+.bottom
  fi
  tmuxAlign
}

function tmuxSplit {
  wins=($(tmux list-windows -F "#I"))
  if [ ${#wins[@]} -eq 1 ];then
    tmux split-window -v
  else
    tmux join-pane -v -s :+.top
  fi
}

function tmuxVSplit {
  wins=($(tmux list-windows -F "#I"))
  if [ ${#wins[@]} -eq 1 ];then
    tmux split-window -h
  else
    tmux join-pane -h -s :+.top
  fi
}

function tmuxOnly {
  wins=($(tmux list-windows -F "#I"))
  if [ ${#wins[@]} -eq 1 ];then
    tmux break-pane
  else
    IFS_ORIG=$IFS
    IFS=$'\n'
    panes=($(tmux list-panes -F "#D #{pane_active}"))
    IFS=$IFS_ORIG
    for line in "${panes[@]}";do
      ip=$(echo "$line"|cut -d' ' -f1)
      fp=$(echo "$line"|cut -d' ' -f2)
      if [ $fp -ne 1 ];then
        tmux move-pane -d -s ${ip} -t :+
      fi
    done
  fi
  tmuxAlign
}

function tmuxFour {
  tmuxOnly
  npanes=1
  wins=($(tmux list-windows -F "#I"))
  if [ ${#wins[@]} -ne 1 ];then
    npanes=$((npanes+$(tmux list-panes -t:+|wc -l)))
  fi
  while [ $npanes -lt 4 ];do
    tmuxCreate
    ((npanes++))
  done
  tmuxVSplit
  tmux select-pane -L
  tmuxSplit
  tmux select-pane -U
  tmux select-pane -R
  tmuxSplit
  tmux select-pane -U
  tmux select-pane -L
}

function tmuxMove {
  wins=($(tmux list-windows -F "#I"))
  if [ ${#wins[@]} -eq 1 ];then
    tmux break-pane
    tmux select-window -t:+
  else
    IFS_ORIG=$IFS
    IFS=$'\n'
    panes=($(tmux list-panes -F "#D #{pane_active}"))
    IFS=$IFS_ORIG
    for line in "${panes[@]}";do
      ip=$(echo "$line"|cut -d' ' -f1)
      fp=$(echo "$line"|cut -d' ' -f2)
      if [ $fp -eq 1 ];then
        tmux move-pane -d -s ${ip} -t :+
      fi
    done
    tmuxAlign
  fi
}

function tmuxNext {
  tmux swap-pane -s :+.top
  tmux rotate-window -U -t :+
  paneinfo=$(tmux list-panes -F "#{pane_active} #D@#T #{pane_current_path}"|grep ^1|sed 's/^1 %//')
  tmux display-message "$paneinfo"
}

function tmuxPrev {
  tmux swap-pane -s :+.bottom
  tmux rotate-window -D -t :+
  paneinfo=$(tmux list-panes -F "#{pane_active} #D@#T #{pane_current_path}"|grep ^1|sed 's/^1 %//')
  tmux display-message "$paneinfo"
}

function tmuxClipborad {
  if [ "$CLX" = "" ];then
    if [[ "$OSTYPE" =~ linux ]];then
      if which -s xsel;then
        CLX="xsel"
      elif which -s xsel;then
        CLX="xclip"
      fi
    elif [[ "$OSTYPE" =~ cygwin ]];then
      if which -s putclip;then
        CLX="putclip"
      elif which -s xsel;then
        CLX="xsel"
      elif which -s xsel;then
        CLX="xclip"
      fi
    elif [[ "$OSTYPE" =~ darwin ]];then
      if which -s pbcopy;then
        CLX="pbcopy"
      fi
    fi
  fi
  if [ "$CLX" != "" ];then
    tmux save-buffer -| $CLX
    tmux display-message "clipboard: $(tmux save-buffer -)"
  else
    tmux display-message "No clipboard software is found."
  fi
}

if [ "$1" = "status" ];then
  tmuxStatus
elif [ "$1" = "winname" ];then
  tmuxWindowName
elif [ "$1" = "left" ];then
  tmuxLeft
elif [ "$1" = "create" ];then
  tmuxCreate
elif [ "$1" = "align" ];then
  tmuxAlign
elif [ "$1" = "split" ];then
  tmuxSplit
elif [ "$1" = "vsplit" ];then
  tmuxVSplit
elif [ "$1" = "only" ];then
  tmuxOnly
elif [ "$1" = "four" ];then
  tmuxFour
elif [ "$1" = "move" ];then
  tmuxMove
elif [ "$1" = "next" ];then
  tmuxNext
elif [ "$1" = "prev" ];then
  tmuxPrev
elif [ "$1" = "clip" ];then
  tmuxClipborad
fi
