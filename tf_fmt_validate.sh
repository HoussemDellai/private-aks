# /bin/bash

tf_folders=(stage0 stage1 stage3 stage4)
for d in "${tf_folders[@]}" ; do
    echo "$d ---------------------------------"
    cd $d
    echo "terraform fmt"
    terraform fmt
    echo "terraform init"
    # terraform init
    # echo "terraform plan -out tfplan"
    # terraform plan -out tfplan
    # echo "terraform validate"
    # terraform validate
    cd ..
done

# # for d in */ ; do
# tf_folders=(stage0 stage1 stage2 stage3 stage4 stage5)
# for d in "${tf_folders[@]}" ; do
#     echo "$d ---------------------------------"
#     echo "terraform fmt $d"
#     terraform fmt $d
#     echo "terraform init $d"
#     terraform init $d
#     echo "terraform validate $d"
#     terraform validate $d
# done