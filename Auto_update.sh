#!/bin/bash

# functions
# Generate a new branch, args = branch_name, opensource_branch
function new_branch(){
    branch_name=$1
    opensource_branch=$2
    git checkout master
    git pull origin master
    git checkout -b "$branch_name"
    git fetch --all
    rebase_msg="$(git pull --rebase opensource "$opensource_branch" 2>&1)"
    # rebase conflicts exist
    if [[ "$rebase_msg" =~ "CONFLICT" ]]
    then
        # should manually rebase
        echo "rebase conflict"
        git rebase --abort 
        git branch -D "$branch_name"
        return 1
    else
        echo "rebase success"
        git push -u origin "$branch_name"
        return 0
    fi    
}

# Create sub_branch from branch_name
# args: sub_branch, branch_name, dir_1
function new_sub_branch(){
    sub_branch=$1
    branch_name=$2
    dir_1=$3
    cd "$dir_1" 
    git checkout "$branch_name"
    git pull
    git checkout -b "$sub_branch" 
    git push origin -u "$sub_branch"    
    git checkout master
    return 0
}

# Rebase branch_1 onto branch_2
# args: branch_1, branch_2, dir_1
function rebase_branch(){
    branch_1=$1
    branch_2=$2
    dir_1=$3
    cd "$dir_1"
    git checkout master
    git pull
    git checkout "$branch_1"
    rebase_msg="$(git rebase "${branch_2}" 2>&1)"
    echo -e "\n\nrebase_msg: ${rebase_msg}"
    if [[ "$rebase_msg" =~ "CONFLICT" ]]
    then
        echo "rebase conflict"
        git rebase --abort
        return 1
    else
       echo "rebase success"
       git push #-f origin "$branch_1"
       git checkout master
       return 0
     fi
}

# Assume we have the branch pulled in our local repo
# args = branch_name, fetch_branch, timeslot_or_date, conflicts_dir 
# timeslot_or_date should follow git <date> format
# if conflicts exist in this time slot, save commits_id in conflict_dir
function update_branch(){
    branch_name=$1
    fetch_branch=$2
    timeslot_or_date=$3
    conflicts_dir=$4

    echo $(date +"%x %r")  >> "$conflicts_dir"   
    git checkout master
    git pull
    git fetch --all
    git checkout "$branch_name"
    commits=$(git log "$fetch_branch" --since="$timeslot_or_date" --pretty=format:"%H")         
    cnt_conflict=0
    cnt_success=0
    cnt_empty=0
    for line in $commits;
    do
        echo "commits: ${line}"
        cherry_msg="$(git cherry-pick "${line}" 2>&1)"
        status_msg=$(git status -s)
        echo "status_msg: ${status_msg}"
        git status
        # echo "cherry_msg: ${cherry_msg}" 
        # no conflict in cherry-pick
        if [[ -z "$status_msg" && ("$cherry_msg" =~ "file changed" || "$cherry_msg" =~ "files changed") ]]
        then
            echo "cherry-pick successes"
            git push
            let cnt_success=$(( $cnt_success + 1 ))
        # conflicts     
        elif [[ "$cherry_msg" =~ "error:" ]]
        then 
            echo "cherry-pick conflicts"
            git cherry-pick --abort
            echo "${fetch_branch}:${line}" >> "$conflicts_dir"   
            let cnt_conflict=$(( $cnt_conflict + 1 ))
        # empty commits               
        elif [[ "$cherry_msg" =~ "git commit --allow-empty" ]]
        then    
            echo "empty commit"
            git reset
            let cnt_empty=$(( $cnt_empty + 1 ))
        # Bad object ???    
        elif [[ "$cherry_msg" =~ "fatal: bad object" ]]
        then    
            echo "Bad object"
            return 1           
        else
            echo "Other cases"
            echo "cherry_msg: ${cherry_msg}"
            echo "status_msg: ${status_msg}"
        fi
    done
    # manually solve conflicts
    echo "cnt_conflict: $cnt_conflict"
    echo "cnt_empty: $cnt_empty"
    echo -e "cnt_success: $cnt_success\n\n"
    if [[ $cnt_conflict == 0 ]]
    then
        return 0
    else
        return 1           
    fi
}

# Cherry-pick specific commits onto beanch_name
# args: branch_name commit_id
function cherry_pick(){
    branch_name=$1
    commit_id=$2
    git checkout master
    git pull origin master
    git fetch --all
    git checkout "$branch_name"
    git pull origin "${branch_name}"
    cherry_msg="$(git cherry-pick "$commit_id" 2>&1)"
    status_msg=$(git status -s)
    git status
    echo -e "\n\nstatus_msg: ${status_msg}"
    echo "cherry_msg: ${cherry_msg}" 
    echo "commit_id: $commit_id"
    if [[ -z "$status_msg" && ("$cherry_msg" =~ "file changed" || "$cherry_msg" =~ "files changed") ]]
    then
        echo "cherry-pick successes"
        git push
    elif [[ "$cherry_msg" =~ "error:" ]]
    then 
        echo "cherry-pick conflicts"
        git cherry-pick --abort
        echo "${fetch_branch}:${line}" >> "$conflicts_dir"   
    elif [[ "$cherry_msg" =~ "git commit --allow-empty" ]]
    then    
        echo "empty commit"
        git reset
    elif [[ "$cherry_msg" =~ "fatal: bad object" ]]
    then    
        echo "Bad object"
        return 1           
    else
        echo "Other cases"
    fi  
}

# Merge branch after resolving conflicts, merge sub_branch to branch and delete sub_branch
# args: branch_name, sub_branch_name, 
function merge_branch(){
    branch_name=$1
    sub_branch_name=$2
    git checkout master
    git pull --allow-unrelated-histories
    git checkout "$branch_name"
    git fetch --all
    merge_msg="$(git merge "$sub_branch_name" 2>&1)"
    echo -e "merge_msg: $merge_msg\n\n"
    if [[ "$merge_msg" =~ "files changed" || "$merge_msg" =~ "file changed" ]]
    then
        echo "merge success"
        git push
       ##git push origin --delete "$sub_branch_name"
        git checkout master
       ##git branch -D "$sub_branch_name"
    elif [[ "$merge_msg" =~ "failed" || "$merge_msg" =~ "CONFLICT" ]]
    then
        echo "merge conflicts"
        git merge --abort
        # manually merge
    else
        echo "merge other"
        #git merge --abort
        return 1
    fi
    return 0                   
}

# Delete sub_branch from local and remote
# args: sub_branch, dir
delete_branch(){
    sub_branch=$1
    dir=$2
    cd "$dir"
    git checkout master
    git branch -D "$sub_branch"
    git push origin --delete "$sub_branch"
    git branch 
    return 0
}


# Test here
#cd hhhh
#dir="/Users/yjin/git/conflicts_file.txt"

#Case1
#new_branch "B3" "master"
#update_branch "B3" "origin/master" "1 hour ago" "/Users/yjin/git/conflicts_file.txt"
#update_branch "B3" "opensource/master" "1 hour ago" "/Users/yjin/git/conflicts_file.txt"

#Case2
#update_branch "B2" "origin/master" "4 hour ago" "$dir"
#update_branch "B2" "opensource/master" "4 hour ago" "$dir"
#update_branch "B2" "opensource/master" "4 hour ago" "$dir"

#Case3
#new_sub_branch "sub_B2" "B2" 

#Case4
#update_branch "sub_B2" "origin/master" "1 hour ago" "$dir"
#update_branch "sub_B2" "opensource/master" "1 hour ago" "$dir"

#Case5
#merge_branch "B2" "sub_B2"

#Case6
#update_branch "B2" "opensource/master" "30 minutes" "$dir"
#update_branch "B2" "origin/master" "30 minutes" "$dir"
#new_sub_branch "sub_B2_0" "B2"
#update_branch "sub_B2_0" "opensource/master" "30 minutes" "$dir"
#update_branch "sub_B2_0" "origin/master" "30 minutes" "$dir"
#update_branch "B2" "origin/master" "5 minutes" "$dir"
#update_branch "B2" "opensource/master" "5 minutes" "$dir"
#new_sub_branch "sub_B2_1" "B2"
#merge_branch "B2" "sub_B2_0"
#merge_branch "B2" "sub_B2_1"

#Case7
#new_sub_branch "sub_B2_3" "B2"
#new_sub_branch "sub_B2_4" "B2"
#merge_branch "B2" "sub_B2_3"
#merge_branch "B2" "sub_B2_4"

#Case8
#delete_branch "sub_B2_5"
#delete_branch "sub_B2_6"
#new_sub_branch "sub_B2_5" "B2"
#new_sub_branch "sub_B2_6" "B2"
#rebase_branch "sub_B2_5" "sub_B2_6"

#Case9
#delete_branch "sub_m0"
#delete_branch "sub_m1"
#new_sub_branch "sub_B2_c9_1" "B2"
#new_sub_branch "sub_B2_c9_2" "B2"
#rebase_branch "sub_B2_c9_1" "origin/master"
#cherry_pick "sub_B2_c9_2" "506e8a33b38befc4299cd277b3d6bbc12c0d7fae"
#new_sub_branch "sub_B2_c9_3" "B2"
#new_sub_branch "sub_B2_c9_4" "B2"
#new_sub_branch "sub_B2_c9_5" "B2"
#new_sub_branch "sub_B2_c9_6" "B2"
#rebase_branch "sub_B2_c9_5" "sub_B2_c9_3"
#echo "-----------I am split line------------"
#merge_branch "sub_B2_c9_6" "sub_B2_c9_4"

#Case10
#new_sub_branch "sub_B2_c10_1" "B2"
#new_sub_branch "sub_B2_c10_2" "B2"
#new_sub_branch "sub_B2_c10_3" "B2"
#new_sub_branch "sub_B2_c10_4" "B2"
#cherry_pick "sub_B2_c10_3" "55712d28e0a14ca1d58fc61c5173f049fd62ef43"
#cherry_pick "sub_B2_c10_4" "55712d28e0a14ca1d58fc61c5173f049fd62ef43"
#rebase_branch "sub_B2_c10_1" "sub_B2_c10_3"
#echo "-----------I am split line------------"
#merge_branch "sub_B2_c10_2" "sub_B2_c10_4"

#Case11
#merge_branch "sub_B2_c9_5" "sub_B2_c10_1"

#Case12
#new_sub_branch "sub_B2_c12_0" "B2"
#new_sub_branch "QR2" "B2"
#rebase_branch "origin/QR2" "B2"
#echo "-----------I am split line------------"
#rebase_branch "opensource/OR2" "B2"

#rebase_branch "sub_B2_c10_1" "opensource/B1" "hhhh"
#delete_branch "opensource/B1"



#dir=$1
#branch_name=$2
#origin_master=$3
#opensource_branch=$4
#time=$5
#conflict_commitsId=$6

#echo "$dir"
#echo "$branch_name"
#echo "$origin_master"
#echo "$opensource_branch"
#echo "$time"
#echo "$conflict_commitsId"

# ensure .git/config is right

#cd "$dir"
#sub_branch "sub_B2_5" "B2"update_branch "$branch_name" "$origin_master" "$time" "$conflict_commitsId"
#update_branch "$branch_name" "$opensource_branch" "$time" "$conflict_commitsId"


 
