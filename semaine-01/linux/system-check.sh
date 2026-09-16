#!/bin/bash

echo "=== SYSTEM CHECK ==="
echo "Date : $(date)"
echo "User : $(whoami)"
echo "Hostname : $(hostname)"
echo ""
echo "=== DISK ==="
df -h | grep /dev/sdd
echo ""
echo "=== MEMORY ==="
free -h | grep Mem
echo ""
echo "=== PROCESSES ==="
ps aux | wc -l
echo "processus actifs"
