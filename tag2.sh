#!/bin/bash -xv 

function update_branch(){
    
    QB=$1
    OB=$2
    OQB=$3
    pre_QB=$4
    pre_OB=$5
    pre_OQB=$6
    commit_a=$7

    git fetch --all
    git checkout $QB
    cur_time=$(date "+%H_%M_%d_%m_%y")
    QB_tag=v-${cur_time}_${QB}
    OB_tag=v-${cur_time}_${OB}
    OQB_tag=v-${cur_time}_${OQB}
    # get previous tag name 
    pre_QB_tag=`git cat-file -p $(git rev-parse ${pre_QB}) | tail -n +6`
    pre_OB_tag=`git cat-file -p $(git rev-parse ${pre_OB}) | tail -n +6`
    pre_OQB_tag=`git cat-file -p $(git rev-parse ${pre_OQB}) | tail -n +6`
    
    # on QB branch 
    git tag ${QB_tag} -m "last tag: ${pre_QB_tag}"
    # empty sub-branch with -i may have bug of staying in QB_tag
    git rebase -i --onto origin/${OQB} ${pre_QB} ${QB_tag}
    pause
    # should be in temp OQB branch
    last_commit=`git log -1 --grep="add tag" --pretty="%H"`
    git commit --allow-empty -m "add tag ${OQB_tag}_1 $(echo -e "\n\norigin/${QB} branch from ${pre_QB_tag}:") `git log ${pre_QB_tag} -1` $(echo -e  "\n\nto ${QB_tag}:") `git log ${QB_tag} -1` $(echo -e  "\n\nlast tag-commit:") ${last_commit}"
    git tag ${OQB_tag}_1 -m "last tag: ${pre_OQB_tag}"
 
    # on OB branch
    git checkout opensource/${OB}
    if ! [[  -z "$commit_a" ]]
    then
        # from opensource branch, to commit_a else current place
        git tag ${OB_tag} ${commit_a} -m "last tag: ${pre_OB_tag}"
    else
        git tag ${OB_tag} -m "last tag: ${pre_OB_tag}"
    fi
    git rebase -i --onto ${OQB_tag}_1 ${pre_OB} ${OB_tag}
    pause
    last_commit=`git log -1 --grep="add tag" --pretty="%H"`
    git commit --allow-empty -m "`echo -e "add tag ${OQB_tag}_2"` `echo -e "\n\nopensource/${OB} branch from ${pre_OB_tag}:"` `git log ${pre_OB_tag} -1` `echo -e "\n\nto ${OB_tag}:"` `git log ${OB_tag} -1` $(echo -e  "\n\nlast tag-commit:") ${last_commit}"
    git tag ${OQB_tag}_2 -m "last tag: ${OQB_tag}_1"
    
    # on OQB branch
    git checkout ${OQB}
    # -i mode may not rebase
    git rebase ${OQB_tag}_2
    pause
    git push

    git tag -d ${pre_QB}
    git tag -d ${pre_OB}
    git tag -d ${pre_OQB}
    git push origin --delete $pre_QB
    git push origin --delete $pre_OB
    git push origin --delete $pre_OQB
    git tag $pre_QB ${QB_tag} -m "${QB_tag}"
    git tag $pre_OB ${OB_tag} -m "${OB_tag}"
    git tag $pre_OQB ${OQB_tag}_2 -m "${OQB_tag}_2"
    git push origin --tags
} 
    
function pause(){
       echo "Press [Enter] key to continue..."
       read -p "$*"
}

#cd Hive-JSON-Serde
#update_branch "QB" "develop" "OQB" "pre_QB" "pre_OB" "pre_OQB" "9878a3ef685da69c41ba78f7b73eee6c4ee48499"  


function update_one_branch(){
    
    QB=$1
    OQB=$2
    pre_QB=$3
    pre_OQB=$4
    commit_a=$5
    place=$6

    git fetch --all
    git checkout "${place}/${QB}"
    cur_time=$(date "+%H_%M_%d_%m_%y")
    QB_tag=v-${cur_time}_${QB}
    OQB_tag=v-${cur_time}_${OQB}
    # get previous tag name 
    pre_QB_tag=`git cat-file -p $(git rev-parse ${pre_QB}) | tail -n +6`
    pre_OQB_tag=`git cat-file -p $(git rev-parse ${pre_OQB}) | tail -n +6`
    
    # on branch
    git checkout "${place}/${QB}"
    if ! [[  -z "$commit_a" ]]
    then
        # from opensource branch, to commit_a else current place
        git tag ${QB_tag} ${commit_a} -m "last tag: ${pre_QB_tag}"
    else
        git tag ${QB_tag} -m "last tag: ${pre_QB_tag}"
    fi
    git rebase -i --onto origin/${OQB} ${pre_QB} ${QB_tag}
    pause
    last_commit=`git log -1 --grep="add tag" --pretty="%H"`
    git commit --allow-empty -m "`echo -e "add tag ${OQB_tag}"` `echo -e "\n\n${place}/${QB} branch from ${pre_QB_tag}:"` `git log ${pre_QB_tag} -1` `echo -e "\n\nto ${QB_tag}:"` `git log ${QB_tag} -1` $(echo -e  "\n\nlast tag-commit:") ${last_commit}"
    git tag ${OQB_tag} -m "last tag: ${pre_OQB_tag}"
    
    # on OQB branch
    git checkout ${OQB}
    # -i mode may not rebase
    git rebase ${OQB_tag}
    #git push

    #git tag -d ${pre_QB}
    #git tag -d ${pre_OQB}
    #git push origin --delete $pre_QB
    #git push origin --delete $pre_OQB
    #git tag $pre_QB ${QB_tag} -m "${QB_tag}"
    #git tag $pre_OQB ${OQB_tag}_2 -m "${OQB_tag}_2"
    #git push origin --tags
} 
    

cd hive
update_one_branch "branch-2.1" "combine_branch"  "pre_OB" "pre_OQB" "" "opensource"      
