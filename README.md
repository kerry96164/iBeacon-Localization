# 室內定位系統 - 嵌入式系統設計期末專題
![image](https://github.com/kerry96164/iBeacon-Localization/blob/main/Report/app_layout.png)
## 專案簡介
本專案旨在利用 iBeacon 技術實現室內使用者的即時定位。考量到特定場地配置可能不利於傳統的 Propagation Model-based 演算法，我們決定採用基於 Fingerprinting 的演算法來達成更精準的定位。
* 實驗場景可參考 Project Competition Deployment2024.pdf。
* 實驗報告可參考 Final_Report.pdf。

## 動機與目標
* **動機**: 觀察到在複雜的室內環境中，傳統的定位方法可能面臨訊號干擾、多徑效應等挑戰，導致定位精度下降。iBeacon 作為一種低功耗、高精度的室內定位技術，提供了解決這些問題的潛力。
* **目標**:
    * 利用 iBeacon 收集 RSSI (Received Signal Strength Indicator) 數據。
    * 開發並實現一種改良的 Fingerprinting-based 定位演算法。
    * 在特定室內環境中驗證系統的即時定位能力。

## 特色
* **基於 iBeacon 技術**: 採用廣泛應用於室內定位的 iBeacon 設備，提供穩定可靠的訊號來源。
* **優化 Fingerprinting 演算法**: 採用改良的 K-Nearest Neighbors (KNN) 演算法，並結合區域選擇與加權座標計算，以提高定位精度並減少訊號干擾的影響。
* **考量非線性關係**: 在演算法中考慮了 RSSI 與實際距離之間的非線性關係 ($PL_d = PL_0 + 10n \log \frac{d}{d_0}$)，使得距離估算更為準確。

## 演算法說明

本專案主要採用 **Fingerprinting-based** 演算法，並進行改良，以應對室內訊號浮動的問題。

### 1. 訊號干擾與挑戰
在室內空間中，即使 iBeacon 和接收設備的位置固定，收到的訊號強度 (RSSI) 也會因環境複雜性而浮動。一個好的定位演算法需要能解決訊號被干擾的問題。

### 2. Fingerprinting-based 演算法核心概念
* **離線階段 (訓練)**: 事先在目標區域內的各個參考點收集 iBeacon 的 RSSI 數據，建立一個訊號指紋資料庫 (fingerprint map)。
* **線上階段 (定位)**: 當設備需要定位時，測量當前位置的 iBeacon RSSI 數據，並將其與資料庫中的指紋進行比對，找出最匹配的指紋，進而推斷設備的當前位置。

### 3. 改良的 KNN 演算法 (Improved KNN)
為了提高定位精度並避免遙遠參考點的影響，我們採用了以下改良策略：

* **區域選擇 (Region Selection)**:
    1.  找出和目前 RSSI 最接近的 K 個參考點。
    2.  以這 K 個參考點作為中心，創建 K 個類別。
    3.  如果其他參考點與某類別中心距離小於 $M$ 公尺，則將其加入該類別。
    4.  選擇成員最多的類別作為最終的選定區域。這個步驟有助於排除異常值和不相關的參考點，集中在最有可能的區域進行定位。

* **加權座標計算 (M-WKNN matching algorithm)**:
    * 在選定的區域內，利用訊號強度與距離的非線性關係來計算加權座標。
    * 公式考慮了 $RSSI$ 與 $\log(d)$ 之間的近似線性關係 ($\Delta RSSI \propto \log d$)，使得越近的參考點權重越高，對最終定位結果的影響越大。
    * 最終位置 $(x, y)$ 由選定類別中所有參考點的加權平均值計算得出。

## 開發環境
* Xcode 15.2
* macOS 13.6.4
* Test in iPad Air 4
