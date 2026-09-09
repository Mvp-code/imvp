/**
 * MVPG Toast Notification System  —  mvpg-toast.js
 *
 * Replaces all browser alert() calls with styled, non-blocking toasts.
 *
 * Usage:
 *   mvpgToast.success('Record saved.');
 *   mvpgToast.error('Problem updating status.');
 *   mvpgToast.warning('Duplicate employee selected.');
 *   mvpgToast.info('SMS sent to 3 associates.');
 *
 * Drop-in replacement for alert():
 *   OLD:  alert("Problem in updating status");
 *   NEW:  mvpgToast.error("Problem in updating status");
 *
 * Version: 1.0  /  2026-04-08
 */

(function (global) {
  'use strict';

  var CONTAINER_ID = 'mvpg-toast-container';
  var AUTO_DISMISS_MS = 4500;

  var ICONS = {
    success: '&#10003;',   // ✓
    error:   '&#10007;',   // ✗
    warning: '&#9888;',    // ⚠
    info:    '&#9432;'     // ℹ
  };

  var COLORS = {
    success: { bg: '#ecfdf5', border: '#6ee7b7', icon: '#059669', text: '#065f46' },
    error:   { bg: '#fef2f2', border: '#fca5a5', icon: '#dc2626', text: '#7f1d1d' },
    warning: { bg: '#fffbeb', border: '#fcd34d', icon: '#d97706', text: '#78350f' },
    info:    { bg: '#ecfeff', border: '#67e8f9', icon: '#0891b2', text: '#164e63' }
  };

  /* ── Container ─────────────────────────────────────────────────── */
  function _getContainer() {
    var el = document.getElementById(CONTAINER_ID);
    if (!el) {
      el = document.createElement('div');
      el.id = CONTAINER_ID;
      el.setAttribute('aria-live', 'polite');
      el.setAttribute('aria-atomic', 'false');
      el.style.cssText = [
        'position:fixed',
        'top:1.1rem',
        'right:1.1rem',
        'z-index:100000',
        'display:flex',
        'flex-direction:column',
        'gap:0.55rem',
        'max-width:360px',
        'width:calc(100% - 2.2rem)',
        'pointer-events:none'
      ].join(';');
      document.body.appendChild(el);

      /* Inject animation keyframes once */
      if (!document.getElementById('mvpg-toast-style')) {
        var style = document.createElement('style');
        style.id = 'mvpg-toast-style';
        style.textContent = [
          '@keyframes mvpg-toast-in{',
          '  from{opacity:0;transform:translateX(110%)}',
          '  to  {opacity:1;transform:translateX(0)}',
          '}',
          '@keyframes mvpg-toast-out{',
          '  from{opacity:1;transform:translateX(0);max-height:120px;margin-bottom:0}',
          '  to  {opacity:0;transform:translateX(110%);max-height:0;margin-bottom:-0.55rem}',
          '}'
        ].join('');
        document.head.appendChild(style);
      }
    }
    return el;
  }

  /* ── Create one toast ──────────────────────────────────────────── */
  function _show(type, message) {
    var c = COLORS[type] || COLORS.info;
    var icon = ICONS[type] || ICONS.info;
    var container = _getContainer();

    var toast = document.createElement('div');
    toast.setAttribute('role', 'alert');
    toast.style.cssText = [
      'display:flex',
      'align-items:flex-start',
      'gap:0.65rem',
      'background:' + c.bg,
      'border:1px solid ' + c.border,
      'border-radius:10px',
      'padding:0.75rem 0.85rem',
      'box-shadow:0 8px 24px rgba(15,23,42,0.13)',
      'font-family:system-ui,"Segoe UI",Roboto,Arial,sans-serif',
      'font-size:0.87rem',
      'line-height:1.45',
      'color:' + c.text,
      'pointer-events:all',
      'cursor:default',
      'animation:mvpg-toast-in 0.28s cubic-bezier(0.16,1,0.3,1) forwards',
      'overflow:hidden'
    ].join(';');

    /* Icon badge */
    var iconEl = document.createElement('span');
    iconEl.innerHTML = icon;
    iconEl.setAttribute('aria-hidden', 'true');
    iconEl.style.cssText = [
      'flex-shrink:0',
      'width:1.4rem',
      'height:1.4rem',
      'border-radius:50%',
      'background:' + c.icon,
      'color:#fff',
      'display:flex',
      'align-items:center',
      'justify-content:center',
      'font-size:0.78rem',
      'font-weight:700',
      'margin-top:0.05rem'
    ].join(';');

    /* Message */
    var msgEl = document.createElement('span');
    msgEl.style.cssText = 'flex:1;word-break:break-word;';
    msgEl.textContent = message;

    /* Close button */
    var closeBtn = document.createElement('button');
    closeBtn.innerHTML = '&times;';
    closeBtn.setAttribute('aria-label', 'Dismiss');
    closeBtn.style.cssText = [
      'flex-shrink:0',
      'background:none',
      'border:none',
      'font-size:1.1rem',
      'line-height:1',
      'color:' + c.text,
      'opacity:0.55',
      'cursor:pointer',
      'padding:0 0 0 0.3rem',
      'margin-top:-0.1rem',
      'transition:opacity 0.15s'
    ].join(';');
    closeBtn.addEventListener('mouseover', function () { this.style.opacity = '1'; });
    closeBtn.addEventListener('mouseout',  function () { this.style.opacity = '0.55'; });
    closeBtn.addEventListener('click', function () { _dismiss(toast); });

    toast.appendChild(iconEl);
    toast.appendChild(msgEl);
    toast.appendChild(closeBtn);
    container.appendChild(toast);

    /* Auto dismiss */
    var timer = setTimeout(function () { _dismiss(toast); }, AUTO_DISMISS_MS);

    /* Pause auto-dismiss on hover */
    toast.addEventListener('mouseenter', function () { clearTimeout(timer); });
    toast.addEventListener('mouseleave', function () {
      timer = setTimeout(function () { _dismiss(toast); }, AUTO_DISMISS_MS);
    });
  }

  function _dismiss(toast) {
    toast.style.animation = 'mvpg-toast-out 0.32s ease forwards';
    setTimeout(function () {
      if (toast.parentNode) toast.parentNode.removeChild(toast);
    }, 340);
  }

  /* ── Public API ────────────────────────────────────────────────── */
  global.mvpgToast = {
    success: function (msg) { _show('success', msg); },
    error:   function (msg) { _show('error',   msg); },
    warning: function (msg) { _show('warning', msg); },
    info:    function (msg) { _show('info',    msg); }
  };

}(window));
