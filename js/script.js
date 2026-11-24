/* ---------------------------------------------------------------
   聖誕楓景 · 互動腳本
   1. Canvas 飄雪
   2. 前後比較滑桿
   3. 區塊進場顯示
   --------------------------------------------------------------- */

(function () {
  "use strict";

  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  /* ---------------- 1. Canvas 飄雪 ---------------- */
  function initSnow() {
    const canvas = document.getElementById("snow");
    if (!canvas || reduceMotion) return;

    const ctx = canvas.getContext("2d");
    let width = 0;
    let height = 0;
    let flakes = [];
    let rafId = null;

    // 依螢幕大小決定雪花數量
    function targetCount() {
      const area = width * height;
      return Math.min(180, Math.max(60, Math.round(area / 12000)));
    }

    function makeFlake(spawnTop) {
      const depth = Math.random();               // 0 = 遠景小雪花, 1 = 近景大雪花
      return {
        x: Math.random() * width,
        y: spawnTop ? -20 - Math.random() * height * 0.3 : Math.random() * height,
        r: 1 + depth * 3.4,                      // 半徑
        speed: 0.35 + depth * 1.25,              // 下落速度
        drift: (Math.random() - 0.5) * 0.7,      // 水平漂移
        sway: Math.random() * Math.PI * 2,       // 搖擺相位
        swaySpeed: 0.008 + Math.random() * 0.016,
        alpha: 0.35 + depth * 0.55
      };
    }

    function resize() {
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      width = window.innerWidth;
      height = window.innerHeight;
      canvas.width = Math.floor(width * dpr);
      canvas.height = Math.floor(height * dpr);
      canvas.style.width = width + "px";
      canvas.style.height = height + "px";
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

      const count = targetCount();
      flakes = Array.from({ length: count }, () => makeFlake(false));
    }

    function draw() {
      ctx.clearRect(0, 0, width, height);

      for (const f of flakes) {
        f.sway += f.swaySpeed;
        f.y += f.speed;
        f.x += f.drift + Math.sin(f.sway) * 0.4;

        // 超出畫面就從頂端重生
        if (f.y - f.r > height || f.x < -30 || f.x > width + 30) {
          Object.assign(f, makeFlake(true));
        }

        ctx.beginPath();
        ctx.arc(f.x, f.y, f.r, 0, Math.PI * 2);
        ctx.fillStyle = "rgba(255,255,255," + f.alpha + ")";
        ctx.shadowColor = "rgba(255,255,255,0.9)";
        ctx.shadowBlur = f.r * 2;
        ctx.fill();
        ctx.shadowBlur = 0;
      }

      rafId = requestAnimationFrame(draw);
    }

    // 分頁切到背景時暫停，省電
    document.addEventListener("visibilitychange", function () {
      if (document.hidden) {
        if (rafId) cancelAnimationFrame(rafId);
        rafId = null;
      } else if (!rafId) {
        rafId = requestAnimationFrame(draw);
      }
    });

    let resizeTimer = null;
    window.addEventListener("resize", function () {
      clearTimeout(resizeTimer);
      resizeTimer = setTimeout(resize, 200);
    });

    resize();
    rafId = requestAnimationFrame(draw);
  }

  /* ---------------- 2. 前後比較滑桿 ---------------- */
  function initCompare() {
    const box = document.getElementById("compareBox");
    const top = document.getElementById("compareTop");
    const handle = document.getElementById("compareHandle");
    const range = document.getElementById("compareRange");
    if (!box || !top || !handle || !range) return;

    const topImg = top.querySelector("img");

    function apply(percent) {
      const p = Math.max(0, Math.min(100, percent));
      top.style.width = p + "%";
      handle.style.left = p + "%";
      // 讓上層圖片永遠維持完整寬度，避免被裁切變形
      if (topImg) topImg.style.width = box.clientWidth + "px";
      range.value = String(Math.round(p));
    }

    range.addEventListener("input", function () {
      apply(parseFloat(range.value));
    });

    // 支援直接在圖上拖曳（滑鼠 / 觸控）
    let dragging = false;

    function pointToPercent(clientX) {
      const rect = box.getBoundingClientRect();
      return ((clientX - rect.left) / rect.width) * 100;
    }

    function start(e) {
      // range 自己會處理，不重複搶事件
      if (e.target === range) return;
      dragging = true;
      apply(pointToPercent(e.clientX !== undefined ? e.clientX : e.touches[0].clientX));
    }
    function move(e) {
      if (!dragging) return;
      const x = e.clientX !== undefined ? e.clientX : e.touches[0].clientX;
      apply(pointToPercent(x));
    }
    function end() { dragging = false; }

    box.addEventListener("mousedown", start);
    window.addEventListener("mousemove", move);
    window.addEventListener("mouseup", end);
    box.addEventListener("touchstart", start, { passive: true });
    window.addEventListener("touchmove", move, { passive: true });
    window.addEventListener("touchend", end);

    window.addEventListener("resize", function () {
      apply(parseFloat(range.value));
    });

    apply(50);
  }

  /* ---------------- 3. 進場顯示 ---------------- */
  function initReveal() {
    const targets = document.querySelectorAll(".reveal");
    if (!targets.length) return;

    // 沒有 IntersectionObserver 就直接全部顯示
    if (!("IntersectionObserver" in window) || reduceMotion) {
      targets.forEach(function (el) { el.classList.add("is-visible"); });
      return;
    }

    const io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          io.unobserve(entry.target);
        }
      });
    }, { threshold: 0.15, rootMargin: "0px 0px -8% 0px" });

    targets.forEach(function (el) { io.observe(el); });

    // 保險：3 秒後不論如何都顯示，避免內容卡在透明狀態
    setTimeout(function () {
      targets.forEach(function (el) { el.classList.add("is-visible"); });
    }, 3000);
  }

  document.addEventListener("DOMContentLoaded", function () {
    initSnow();
    initCompare();
    initReveal();
  });
})();
