#!/bin/bash

max_failed_pings=10  # 最大不通次数
virtual_machine_ids=("100" )  # 虚拟机号数组
host="baidu.com"  # 目标主机
consecutive_failed_pings=0  # 连续不通次数的初始值
log_file="/root/ping_log.txt"  # 日志文件路径

log_failed_ping() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local log_entry="${timestamp} - ping失败"
    local count_info="($((consecutive_failed_pings))/$max_failed_pings)"
    log_entry+=" ${count_info}"
    echo "$log_entry" >> "$log_file"
    echo "$log_entry"
}

restart_virtual_machine() {
    # 重启虚拟机函数
    for vm_id in "${virtual_machine_ids[@]}"; do
        qm stop "$vm_id"  # 停止虚拟机的命令，根据实际情况进行修改
        sleep 10  # 等待一段时间，确保虚拟机完全停止
        qm start "$vm_id"  # 启动虚拟机的命令，根据实际情况进行修改
    done
}

while true; do
    if ping -c 1 "$host" > /dev/null; then
        if [ $consecutive_failed_pings -gt 0 ]; then
            # 之前发生了连续失败的ping，网络恢复正常，重置连续失败次数
            consecutive_failed_pings=0
            log_entry="[$(date +"%Y-%m-%d %H:%M:%S")] - 网络恢复正常"
            echo "$log_entry" >> "$log_file"
            echo "$log_entry"
        fi
    else
        consecutive_failed_pings=$((consecutive_failed_pings+1))
        log_failed_ping
        if [ $consecutive_failed_pings -ge $max_failed_pings ]; then
            # 达到最大连续失败次数，执行重启虚拟机操作
            restart_virtual_machine
            log_entry="[$(date +"%Y-%m-%d %H:%M:%S")] - 连续失败次数达到上限，重启虚拟机"
            echo "$log_entry" >> "$log_file"
            echo "$log_entry"
			consecutive_failed_pings=0  # 重置连续失败次数为0
			echo "等待下次循环"
			sleep 20s
        fi
    fi

    sleep 120  # 等待一段时间后进行下一次循环，根据需要进行调整
done