#!/bin/bash

exported_file_tmp=/tmp/nvme_smart.prom
exported_file={{ node_exporter_textfile_directory }}nvme_smart.prom

rm -f ${exported_file_tmp} ${exported_file}

echo -e ""

echo -e '# HELP nvme_smart_state NVME S.M.A.R.T device state ' >> ${exported_file_tmp}
echo -e '# TYPE nvme_smart_state gauge' >> ${exported_file_tmp}

for DRIVE in nvme0 nvme1 nvme2 nvme3 nvme4 nvme5
do
        if [ -c /dev/$DRIVE ]
        then
                nvme smart-log /dev/$DRIVE | grep percentage_used'\|'temperature | sed 's/\://' | awk -v var="$DRIVE" '{printf "nvme_smart_state{drive=\""var"\",param=\"%s\"} %d\n", $1, $2 }' >> ${exported_file_tmp}
        fi
done

chmod o+r ${exported_file_tmp}
mv -f ${exported_file_tmp} ${exported_file}

