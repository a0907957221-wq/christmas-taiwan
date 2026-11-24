# 聖誕楓景 · Christmas in Taiwan 🎄

把台灣秋日的楓紅湖景，加上飄雪、暖黃燈串與冬日色調，變成一張充滿聖誕氣氛的照片，並做成一個會下雪的網頁。

## 線上預覽

GitHub Pages：<待填>

## 檔案結構

```
index.html          主頁面
css/style.css       樣式（燈串、卡片、比較滑桿、進場動畫）
js/script.js        Canvas 飄雪、前後比較滑桿、進場顯示
images/christmas.png 聖誕版圖片（原始圖片1.png 位於專案根目錄）
make_christmas.ps1  產生聖誕版圖片的腳本（Windows PowerShell + GDI+）
```

## 聖誕氣氛怎麼做的

### 圖片（離線處理）

`make_christmas.ps1` 以 System.Drawing 逐像素處理：

- **冬日色調**：依亮度決定強度的冷色分級，陰影偏藍綠、亮部維持原樣
- **枝頭積雪**：找出暗色樹枝的上緣，混入白色，模擬積雪
- **暖黃燈串**：在暗色枝幹上散布金色光暈
- **飄雪**：大小不一的雪花，包含前景大顆的散景雪花
- **QR code**：最後把原圖的 QR 區塊貼回，確保掃碼不受影響

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\make_christmas.ps1
```

### 網頁（前端）

- `<canvas>` 繪製動態飄雪，含水平搖擺、離焦大雪花，切到背景分頁自動暫停
- 頂部 CSS 聖誕燈串，18 顆燈泡依序閃爍
- 標題上方的 CSS 積雪裝飾
- 前後比較滑桿，可拖曳或用鍵盤方向鍵
- 區塊進場動畫（IntersectionObserver）
- 尊重 `prefers-reduced-motion`，關閉動態效果

## 技術

純靜態網頁，無建置步驟、無相依套件。字體來自 Google Fonts。

## 授權

圖片版權屬原作者所有，僅供學習與展示用途。
