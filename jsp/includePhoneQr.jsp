<style>
.phqr-modal{position:fixed;inset:0;background:rgba(15,23,42,.45);display:none;align-items:center;justify-content:center;z-index:520;padding:16px}
.phqr-modal.on{display:flex}
.phqr-card{background:#fff;border:1px solid var(--border,#e2e8f0);border-radius:12px;padding:16px 18px;max-width:340px;width:100%;position:relative;text-align:center}
.phqr-card .phqr-x{position:absolute;top:8px;right:8px;border:0;background:transparent;font-size:18px;cursor:pointer;color:#64748b;width:36px;height:36px}
.phqr-card h4{margin:0 28px 4px 0;font-size:15px;font-weight:800;color:var(--text,#16202e);text-align:left}
.phqr-sub{font-size:12px;color:#64748b;margin-bottom:12px;word-break:break-all;font-family:var(--font-mono,ui-monospace,monospace);text-align:left}
.phqr-box{display:inline-flex;justify-content:center;margin:0 auto}
.phqr-scan{position:fixed;inset:0;background:#000;z-index:530;display:none;flex-direction:column}
.phqr-scan.open{display:flex}
.phqr-scan video{flex:1;object-fit:cover;width:100%;background:#111}
.phqr-scan .bar{display:flex;align-items:center;gap:10px;flex-wrap:wrap;padding:12px 14px calc(12px + env(safe-area-inset-bottom));background:#141519}
.phqr-scan .bar span{color:#F4F3EE;font-family:var(--font-mono,ui-monospace,monospace);font-size:12px;flex:1;min-width:140px}
.phqr-scan .bar input{flex:1;min-width:140px;min-height:44px;border-radius:8px;border:1px solid #334155;background:#0f172a;color:#fff;padding:8px 10px;font-size:16px;font-family:inherit}
@media (max-width:700px){
  .phqr-scan .bar{flex-direction:column;align-items:stretch}
  .phqr-scan .bar span{min-width:0}
  .phqr-scan .bar input,.phqr-scan .bar button{width:100%}
}
.da-wrap .tablewrap .ph-qr,.ph-qr{
  border:0;background:transparent;color:var(--text-muted,#64748b);cursor:pointer;
  padding:2px 6px;border-radius:6px;font-size:13px;line-height:1;min-width:32px;min-height:32px
}
.da-wrap .tablewrap .ph-qr:hover,.ph-qr:hover{color:var(--theme-accent,#2563eb);background:var(--bg,#f1f5f9)}
</style>
<div class="phqr-modal" id="phQrModal" onclick="if(event.target===this)MVPxPhoneQr.hide()">
  <div class="phqr-card" role="dialog" aria-label="Phone QR code">
    <button type="button" class="phqr-x" onclick="MVPxPhoneQr.hide()" title="Close" aria-label="Close">&#10005;</button>
    <h4 id="phQrTitle">Phone QR</h4>
    <div class="phqr-sub" id="phQrSub"></div>
    <div class="phqr-box" id="phQrBox"></div>
  </div>
</div>
<div class="phqr-scan" id="phQrScan">
  <video id="phQrVideo" playsinline muted></video>
  <div class="bar">
    <span id="phQrScanHint">Point at the phone QR, or type the number</span>
    <input id="phQrTyped" placeholder="Phone number or IMEI" inputmode="tel" autocomplete="off">
    <button type="button" class="btn2" onclick="MVPxPhoneQr.submitTyped()">Use</button>
    <button type="button" class="btn2" onclick="MVPxPhoneQr.closeScan()">Close</button>
  </div>
</div>
<script src="../jsp/assets/js/mvpx-phone-qr.js?v=20260919a"></script>
