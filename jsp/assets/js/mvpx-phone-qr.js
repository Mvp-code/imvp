(function (w) {
  var stream = null, loop = null, mode = 'in', onDone = null;

  function say(msg, ok) {
    if (typeof mvpxToast === 'function') mvpxToast(msg, ok !== false);
    else if (typeof rbToast === 'function') rbToast(msg, ok !== false);
  }
  function servletUrl() {
    return '../servlet/MVPGServlet';
  }
  function payload(num) {
    var d = String(num || '').replace(/\D/g, '');
    if (d.length === 11 && d.charAt(0) === '1') d = d.substring(1);
    if (d.length > 10) d = d.slice(-10);
    return d ? ('MVPxP:' + d) : '';
  }
  function loadQrLib(cb) {
    if (w.QRCode) { cb(); return; }
    var existing = document.querySelector('script[data-vh-qrcode]');
    if (existing) { existing.addEventListener('load', cb); return; }
    var s = document.createElement('script');
    s.src = 'https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js';
    s.setAttribute('data-vh-qrcode', '1');
    s.onload = cb;
    s.onerror = function () { say('Could not load QR library', false); };
    document.head.appendChild(s);
  }
  function paintRow(d) {
    if (!d || !d.id) return;
    var tr = document.querySelector('#ciRows tr[data-id="' + d.id + '"]');
    if (!tr) return;
    tr.dataset.cur = String(d.cs || '').toLowerCase();
    var tds = tr.querySelectorAll('td');
    var curLc = tr.dataset.cur;
    var pill = 'slate';
    if (curLc === 'in use') pill = 'green';
    else if (curLc === 'damaged') pill = 'amber';
    else if (curLc === 'lost') pill = 'red';
    if (tds[2]) tds[2].innerHTML = '<span class="pill ' + pill + '"><span class="d"></span>' + String(d.cs || '').replace(/</g, '') + '</span>';
  }
  function applyFormHints(d) {
    if (!d || !d.ok) return;
    if (d.mode === 'in') {
      var pc = document.getElementById('phoneCable') || (document.formmain && document.formmain['phoneCable']);
      if (pc && pc.tagName === 'SELECT') pc.value = '1';
      else if (document.formmain && document.formmain['phoneCable']) {
        var radios = document.formmain['phoneCable'];
        if (radios && radios.length) {
          for (var i = 0; i < radios.length; i++) if (radios[i].value === '1') radios[i].checked = true;
        }
      }
    }
    if (d.mode === 'out' && document.formmain && document.formmain['phoneReturned']) {
      var pr = document.formmain['phoneReturned'];
      if (pr.length) {
        for (var j = 0; j < pr.length; j++) if (pr[j].value === '1') pr[j].checked = true;
      }
    }
  }

  var api = {
    show: function (num) {
      var text = payload(num);
      if (!text) { say('No phone number for a QR', false); return; }
      document.getElementById('phQrTitle').textContent = 'Phone · ' + num;
      document.getElementById('phQrSub').textContent = text;
      var box = document.getElementById('phQrBox');
      box.innerHTML = '';
      document.getElementById('phQrModal').classList.add('on');
      loadQrLib(function () {
        box.innerHTML = '';
        new QRCode(box, {
          text: text, width: 180, height: 180,
          colorDark: '#0f172a', colorLight: '#ffffff',
          correctLevel: QRCode.CorrectLevel.M
        });
      });
    },
    hide: function () {
      var m = document.getElementById('phQrModal');
      if (m) m.classList.remove('on');
      var box = document.getElementById('phQrBox');
      if (box) box.innerHTML = '';
    },
    printVisible: function () {
      var rows = [];
      document.querySelectorAll('#ciRows tr[data-id]').forEach(function (tr) {
        if (tr.style.display === 'none') return;
        var num = (tr.getAttribute('data-num') || '').trim();
        var text = payload(num);
        if (text) rows.push({ num: num, text: text });
      });
      if (!rows.length) { say('No phones to print', false); return; }
      var win = window.open('', '_blank');
      if (!win) { say('Allow pop-ups to print QR codes', false); return; }
      win.document.write('<!DOCTYPE html><html><head><title>Phone QR Codes</title><style>'
        + 'body{font-family:Inter,Segoe UI,sans-serif;padding:16px}'
        + 'h1{font-size:16px;margin:0 0 12px}'
        + '.grid{display:flex;flex-wrap:wrap;gap:16px}'
        + '.card{width:180px;text-align:center;page-break-inside:avoid}'
        + '.qr{display:flex;justify-content:center}'
        + '.nm{font-size:13px;font-weight:700;margin-top:6px}'
        + '</style></head><body><h1>Phone QR Codes</h1><div class="grid" id="g"></div></body></html>');
      win.document.close();
      loadQrLib(function () {
        var g = win.document.getElementById('g');
        rows.forEach(function (r) {
          var card = win.document.createElement('div');
          card.className = 'card';
          card.innerHTML = '<div class="qr"></div><div class="nm"></div>';
          card.querySelector('.nm').textContent = r.num;
          g.appendChild(card);
          new QRCode(card.querySelector('.qr'), {
            text: r.text, width: 140, height: 140,
            colorDark: '#0f172a', colorLight: '#ffffff',
            correctLevel: QRCode.CorrectLevel.M
          });
        });
        setTimeout(function () { win.focus(); win.print(); }, 400);
      });
    },
    scan: function (m, cb) {
      mode = m || 'in';
      onDone = typeof cb === 'function' ? cb : null;
      var hint = document.getElementById('phQrScanHint');
      if (hint) hint.textContent = mode === 'out'
        ? 'Scan the phone coming back, or type the number'
        : 'Scan the phone going out, or type the number';
      var typed = document.getElementById('phQrTyped');
      if (typed) typed.value = '';
      var overlay = document.getElementById('phQrScan');
      overlay.classList.add('open');
      var v = document.getElementById('phQrVideo');
      if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } }).then(function (s) {
          stream = s; v.srcObject = s; v.play();
          if ('BarcodeDetector' in w) {
            var det = new BarcodeDetector({ formats: ['qr_code', 'code_128', 'code_39'] });
            loop = setInterval(function () {
              det.detect(v).then(function (codes) {
                if (!codes.length) return;
                var raw = (codes[0].rawValue || '').trim();
                if (raw) api.apply(mode, raw, onDone);
              }).catch(function () {});
            }, 400);
          }
        }).catch(function () {
          if (typed) typed.focus();
        });
      } else if (typed) typed.focus();
      if (typed) {
        typed.onkeydown = function (e) {
          if (e.key === 'Enter') { e.preventDefault(); api.submitTyped(); }
        };
      }
    },
    submitTyped: function () {
      var el = document.getElementById('phQrTyped');
      api.apply(mode, el ? el.value : '', onDone);
    },
    closeScan: function () {
      clearInterval(loop); loop = null;
      if (stream) stream.getTracks().forEach(function (t) { t.stop(); });
      stream = null;
      var overlay = document.getElementById('phQrScan');
      if (overlay) overlay.classList.remove('open');
      var v = document.getElementById('phQrVideo');
      if (v) v.srcObject = null;
    },
    apply: function (m, code, cb) {
      var raw = String(code || '').trim();
      if (!raw) { say('Enter or scan a phone number', false); return; }
      api.closeScan();
      var body = new URLSearchParams();
      body.append('submitType', '10');
      body.append('controller', 'AdminPhones');
      body.append('requestType', 'phoneScan');
      body.append('mode', m || 'in');
      body.append('code', raw);
      ['entityID', 'loginUser', 'loginUserID', 'loginUserRoles', 'loginUserDisplayName'].forEach(function (k) {
        var el = document.getElementById(k); if (el) body.append(k, el.value);
      });
      fetch(servletUrl(), { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: body.toString() })
        .then(function (r) { return r.text(); })
        .then(function (resp) {
          var d; try { d = JSON.parse(resp); } catch (e) { say('Scan failed', false); return; }
          if (!d.ok) { say(d.mesg || 'No match', false); if (cb) cb(d); return; }
          say(d.mesg || 'Updated', true);
          paintRow(d);
          applyFormHints(d);
          if (cb) cb(d);
        })
        .catch(function () { say('Scan failed', false); });
    }
  };
  w.MVPxPhoneQr = api;
})(window);
