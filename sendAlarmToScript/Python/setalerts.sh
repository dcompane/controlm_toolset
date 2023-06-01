#! /bin/bash
set -x

ctm run alerts:listener:script::set /home/saasaapi/extalerts/extalert.sh
ctm run alerts:listener:environment::set $(ctm env show |grep -i current |awk '{print $3}')
ctm run alerts:stream:template::set -f field_names.json
ctm run alerts:stream::status
ctm run alerts:stream::open
ctm run alerts:stream::status
ctm run alerts:listener::start
