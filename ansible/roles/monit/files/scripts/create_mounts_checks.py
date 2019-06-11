#!/usr/bin/env python

import sys

# example run:
# /usr/local/scripts/monit/create_mounts_checks.py /etc/monit.d/

mounts_file_name = '/proc/mounts'
monit_file_name = sys.argv[1] + 'mounts.conf'
fs_vfstype_filter = ['ext4', 'xfs']
local_file_systems_result = dict()
template = [
    '# description: get stats for mount {{ disk_name }}',
    'CHECK FILESYSTEM {{ disk_name }}-P3-team_noalert WITH PATH {{ fs_file }}',
    '',
    '# description: check if mount writable',
    'CHECK PROGRAM {{ disk_name }}_writable-P3-team_noalert PATH "/usr/local/scripts/monit/file_system_writable.sh {{ fs_file }}" EVERY 6 CYCLES',
    '  IF STATUS != 0 THEN alert'
    ]

with open(mounts_file_name) as mounts_file:
    for line in mounts_file:
        fs_spec, fs_file, fs_vfstype, fs_mntops, fs_freq, fs_passno = line.split()
        # skip not writable file systems
        if 'rw' not in fs_mntops.split(','):
            continue
        # skip if fs type not in 'fs_vfstype_filter' list
        if fs_vfstype not in fs_vfstype_filter:
            continue
        # skip docker containers mounts
        if fs_spec.startswith('/dev/mapper/docker'):
            continue
        # write only first mount for any device (skip bind mounts)
        if fs_spec not in local_file_systems_result:
            local_file_systems_result[fs_spec] = fs_file
            continue

with open(monit_file_name, 'w') as monit_file:
    template = '\n'.join(template)
    for fs_spec in local_file_systems_result:
        fs_file = local_file_systems_result[fs_spec]
        disk_name = 'disk_/' + fs_file[1:]
        check = template.replace('{{ disk_name }}', disk_name)
        check = check.replace('{{ fs_file }}', fs_file)
        monit_file.write(check + '\n\n')

for fs_spec in local_file_systems_result:
    print(fs_spec, local_file_systems_result[fs_spec])

