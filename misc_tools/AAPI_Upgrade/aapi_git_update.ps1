#! /bin/pwsh
# This filename: aapi_git_update.ps1
#     Used to be git_control_py.ps1
Set-PSDebug -Trace 0
#Set-PSDebug -Trace 2
$git_id="dcompane"
$git_repo="controlm_py"
$message=$args[0]
# MUST predownload the yaml
$yamlfile="swagger-file.yaml"
$dir=$env:homepath+"\Documents"
cd $dir
rd -r -fo .\$git_repo\
(@"
{
"packageName" : "controlm_py",
"packageVersion":"$message"
}
"@) | set-content swagger-config.json


java -jar swagger-codegen-cli.jar generate `
   -i $yamlfile `
   -l python `
   -o controlm_py `
   -c swagger-config.json 
cd .\$git_repo\
(@"
MIT License

Copyright (c) 2021 Daniel Companeetz, BMC Software, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"@) | set-content LICENSE
git init
git add .
git remote add origin https://github.com/$git_id/$git_repo.git
git pull origin main
((Get-Content -path README.md -Raw) -creplace 'GIT_USER_ID', $git_id ) -creplace 'GIT_REPO_ID',$git_repo | Set-Content -Path README.md
git add README.md
(((Get-Content -path git_push.sh -Raw) -creplace 'GIT_USER_ID',$git_id ) -creplace 'GIT_REPO_ID',$git_repo) -creplace 'Minor update', $message | Set-Content -Path git_push.sh
git add git_push.sh
git commit -a -m $message
git branch -mv master main
git push --force origin main
Set-PSDebug -Trace 0