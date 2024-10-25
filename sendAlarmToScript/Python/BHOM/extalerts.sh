# /bin/bash

#set -vx

echo "$*" | tee -a args_passed.log
echo Which python: $(which python)
echo Using /usr/bin

unset PYTHONHOME
/usr/bin/python $HOME/custom/BHOM/extalert.py "$*" | tee -a extalert.log
#echo.
#echo Using which

#$(which python) /home/saasaapi/extalerts/extalert.py "$*" | tee -a extalert.log
#$(which python) /home/saasaapi/extalerts/extalert.py "$*"

