# WAN-Failover (for Openwrt)

當網路模式為DHCP、Static IP、PPPoE，偵測到網路斷線（ping 8.8.8.8 失敗) 時，需要將網路切換至行動數據(3G/4G)並且偵測原先網路是否恢復正常，恢復正常後關閉行動數據及繼續使用原先設定的網路。
