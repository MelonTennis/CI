#!/bin/bash -xv

function tag(){
    Q_branch=$1    
    O_branch=$2
    OQ_branch=$3
    Q_tag=$4
    O_tag=$5
    Q_tmp="${Q_branch}_tmp"
    O_tmp="${O_branch}_tmp"
    OQ_tmp="${OQ_branch}_tmp"
    OQ_tmp_m="${OQ_branch}_tmp_m"
    Num_branch=$(git branch | wc -l)
    git fetch --all
    git checkout "$Q_branch"
    git checkout -b "$Q_tmp"
    Cnt_commit="$(git log ${Q_tag}..${Q_tmp} --pretty=oneline | wc -l)"
    cnt_err=0
    git status
    git rebase -i --onto "origin/${OQ_branch}" "$Q_tag" "$Q_tmp"
    stat_msg="$(git status 2>&1)"
    echo "$stat_msg"
    while  [[ !( "$stat_msg" =~ "nothing to commit, working tree clean" || "$stat_msg" =~ "Untracked files" ) || ( "$stat_msg" =~ "You are currently rebasing" || "$stat_msg" =~ "Unmerged paths" ) ]]
    do
        pause
        if [[ "$stat_msg" =~ "Unmerged paths" ]]
        then
            cat .git/rebase-merge/stopped-sha >> tmp_conflicts
            rebase_msg="$(git rebase --skip 2>&1)"
            let cnt_err=$(( $cnt_err + 1 ))
            stat_msg="$(git status 2>&1)"
        elif [[ "$stat_msg" =~ "You are currently rebasing" ]] 
        then    
            rebase_msg="$(git reset 2>&1)"
            stat_msg="$(git status 2>&1)"
        else
            rebase_msg="$(git rebase --skip 2>&1)"
            stat_msg="$(git status 2>&1)"      
        fi
        echo "$stat_msg"
    done    
    if (( $cnt_err > 0 ))
    then
        cat tmp_conflicts
        git checkout -b QB1_conflict_branch "$Q_tag"
        git push origin -u QB1_conflict_branch
        git tag v1-c-QB1 "$Q_tag"
        git checkout QB1_conflict_branch
        for f in `cat tmp_conflicts`
        do 
            cherry_msg="$(git cherry-pick $f 2>&1)"
            echo "$cherry_msg"
            if [[ "$cherry_msg" =~ "error:" ]] 
            then
                git cherry-pick --abort
                git tag v2-c-QB1 "$Q_tag"
                git checkout -b QB1_conflict_branch_2 "$Q_tag"
                for f in `cat tmp_conflicts`; do git cherry-pick $f; done
                git push origin -u QB1_conflict_branch_2
            else
                for f in `cat tmp_conflicts`; do git cherry-pick $f; done
                git push
            fi    
        done
    rm tmp_conflicts
    fi   
    git checkout "opensource/${O_branch}"
    git checkout -b "$O_tmp"
    #rebase_msg="$(git rebase --onto "$Q_tmp" "$O_tag" "$O_tmp" 2>&1)"
    echo "$rebase_msg"
    #git rebase -i --onto "$Q_tmp" "$O_tag" "$O_tmp"
    git checkout -b "$OQ_tmp"
    git checkout -b "$OQ_tmp_m"
    git merge "$Q_branch" --no-ff --allow-unrelated-histories -Xours
    git merge "opensource/${O_branch}" --no-ff --allow-unrelated-histories -Xours
    git diff "$OQ_tmp" -p > tmp_patch.patch
    cat tmp_patch.patch
    Line_patch=$(wc -l < tmp_patch.patch)
    if [[ "$Line_patch" -gt 0 ]]
    then
        git checkout "$OQ_tmp"
        git apply --check tmp_patch.patch
        git apply tmp_patch.patch
        git add .
        git commit -m "add patch for revert"
    fi
    rm tmp_patch.patch
    git checkout "$OQ_tmp"
    git log
    git push origin -u "$OQ_tmp"
    #git tag -d "$Q_tag"
    #git tag -d "$O_tag"
    #git push origin --delete "$Q_tag"
    #git push origin --delete "$O_tag"
    #git checkout "$Q_branch"
    #git tag "$Q_tag"
    #git checkout "opensource/${O_branch}"
    #git tag "$O_tag"
    git checkout master
    git branch -D "$Q_tmp"
    git branch -D "$O_tmp"
    git branch -D "$OQ_tmp_m"
    #git push origin --tags
}


function update_manual(){
    Q_branch=$1    
    O_branch=$2
    OQ_branch=$3
    Q_tag=$4
    O_tag=$5
    Q_tmp="${Q_branch}_tmp"
    O_tmp="${O_branch}_tmp"
    OQ_tmp="${OQ_branch}_tmp"
    git fetch --all
    git checkout "$Q_branch"
    git checkout -b "$Q_tmp"
    git rebase -i --onto "origin/${OQ_branch}" "$Q_tag" "$Q_tmp"
    pause
    #rebase_msg="$(git rebase --onto "origin/${OQ_branch}" "$Q_tag" "$Q_tmp" 2>&1)"
    #if ! [[ "$rebase_msg" =~ "Successfully rebased" ]] 
    #then
    #    echo "$rebase_msg"
    #    git status
    #    pause
    #fi
    git checkout "opensource/${O_branch}"
    git checkout -b "$O_tmp"
    git rebase -i --onto "$Q_tmp" "$O_tag" "$O_tmp"
    pause
    #rebase_msg="$(git rebase --onto "$Q_tmp" "$O_tag" "$O_tmp" 2>&1)"
    #if ! [[ "$rebase_msg" =~ "Successfully rebased" ]] 
    #then
    #    echo "$rebase_msg"
    #    git status
    #    pause
    #fi
    git log
    git checkout "$OQ_branch"
    git rebase -i "$O_tmp"
    pause
    #rebase_msg="$(git rebase "$O_tmp" 2>&1)"
    #if ! [[ "$rebase_msg" =~ "Successfully rebased" || "$rebase_msg" =~ "Fast-forwarded" ]] 
    #then
    #    echo "$rebase_msg"
    #    git status
    #    pause
    #fi    
    git push
    #git tag -d "$Q_tag"
    #git tag -d "$O_tag"
    #git push origin --delete "$Q_tag"
    #git push origin --delete "$O_tag"
    #git checkout "$Q_branch"
    #git tag "$Q_tag"
    #git checkout "opensource/${O_branch}"
    #git tag "$O_tag"
    git checkout master
    git branch -D "$Q_tmp"
    git branch -D "$O_tmp"
    #git push origin --tags
    return 0
}


function update_manual_branch(){
    Q_branch=$1    
    OQ_branch=$2
    Q_tag=$3
    Q_tmp="${Q_branch}_tmp"
    OQ_tmp="${OQ_branch}_tmp"
    git fetch --all
    git checkout "opensource/${Q_branch}"
    git checkout -b "$Q_tmp"
    git rebase -i --onto "origin/${OQ_branch}" "$Q_tag" "$Q_tmp"
    pause
    #rebase_msg="$(git rebase --onto "origin/${OQ_branch}" "$Q_tag" "$Q_tmp" 2>&1)"
    #if ! [[ "$rebase_msg" =~ "Successfully rebased" ]] 
    #then
    #    return 1
    #    exit
    #fi
    git checkout "$OQ_branch"
    git rebase -i "$O_tmp"
    pause
    git push
    #git tag -d "$Q_tag"
    #git tag -d "$O_tag"
    #git push origin --delete "$Q_tag"
    #git push origin --delete "$O_tag"
    #git checkout "$Q_branch"
    #git tag "$Q_tag"
    #git tag "$O_tag"
    git checkout master
    git branch -D "$Q_tmp"
    #git push origin --tags
    return 0
}


function pause(){
       echo "Press [Enter] key to continue..."
       read -p "$*"
}


