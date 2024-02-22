# pavi_working_tf


## push an existing Git repository with the following command:

```
cd existing_repo
git init
git status
git remote add origin <branch link or name>
git branch -M main
git add . #add changes
git commit -m "Initial Commit"  #commit 
git commit -am "Initial Commit"  #add and commit together
git push -uf origin main
git diff 
git checkout main
git merge --no-ff first_branch
```
## Terraform Commands:
```
terraform init
terraform plan
terraform fmt
terraform apply -replace="aws_instance.example"
terraform deploy
terraform apply/destroy -auto-approve -input=false
terraform validate
```
