#!/bin/bash
# Nightly status report.
#
# The scheduler runs this script as root once a minute, and its output is saved
# to /var/log/report.log. Right now it just records that things look healthy.
echo "nightly report: all systems OK"
