/**
 * MVPG Async Fetch Utility  —  mvpg-fetch.js
 *
 * Replaces the legacy synchronous setSynXMLHttpOb() pattern.
 * All calls are non-blocking: the browser stays responsive
 * and a loading indicator is shown while the request is in flight.
 *
 * Usage (replaces the old three-liner):
 *
 *   OLD (synchronous – freezes the browser):
 *     var xr = setSynXMLHttpOb("../servlet/MVPGServlet");
 *     xr.send(str);
 *     var xmlMessage = xr.responseXML;
 *     // ... use xmlMessage ...
 *
 *   NEW (async – non-blocking):
 *     mvpgPostXML(str, function(xmlMessage) {
 *       // ... use xmlMessage ...
 *     });
 *
 *   For responseText callers:
 *     mvpgPostText(str, function(text) {
 *       // ... use text ...
 *     });
 *
 * Version: 1.0  /  2026-04-08
 */

(function (global) {
  'use strict';

  function resolveServletUrl() {
    if (typeof global.MVPG_SERVLET_URL === 'string' && global.MVPG_SERVLET_URL.length > 0) {
      return global.MVPG_SERVLET_URL;
    }
    return '../servlet/MVPGServlet';
  }

  /* ── Loading indicator ─────────────────────────────────────────── */
  var _loadingCount = 0;

  function _showLoading() {
    _loadingCount++;
    var el = document.getElementById('mvpg-loading-bar');
    if (!el) {
      el = document.createElement('div');
      el.id = 'mvpg-loading-bar';
      el.setAttribute('aria-hidden', 'true');
      el.style.cssText = [
        'position:fixed', 'top:0', 'left:0', 'right:0', 'height:3px',
        'background:linear-gradient(90deg,#0f766e,#14b8a6,#0f766e)',
        'background-size:200% 100%',
        'animation:mvpg-bar-slide 1.2s linear infinite',
        'z-index:99999', 'display:block'
      ].join(';');
      // inject keyframes once
      if (!document.getElementById('mvpg-bar-style')) {
        var style = document.createElement('style');
        style.id = 'mvpg-bar-style';
        style.textContent = '@keyframes mvpg-bar-slide{0%{background-position:200% 0}100%{background-position:-200% 0}}';
        document.head.appendChild(style);
      }
      document.body.appendChild(el);
    }
    el.style.display = 'block';
  }

  function _hideLoading() {
    _loadingCount = Math.max(0, _loadingCount - 1);
    if (_loadingCount === 0) {
      var el = document.getElementById('mvpg-loading-bar');
      if (el) el.style.display = 'none';
    }
  }

  /* ── Core fetch wrapper ────────────────────────────────────────── */
  function _doFetch(bodyStr, responseType, onSuccess, onError) {
    _showLoading();
    fetch(resolveServletUrl(), {
      method: 'POST',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
      body: bodyStr
    })
    .then(function (resp) {
      if (!resp.ok) {
        throw new Error('HTTP ' + resp.status + ' ' + resp.statusText);
      }
      return responseType === 'xml' ? resp.text() : resp.text();
    })
    .then(function (text) {
      _hideLoading();
      if (responseType === 'xml') {
        var raw = text || '';
        var t = raw.trim();
        if (t.length === 0) {
          if (typeof onError === 'function') {
            onError(new Error('Empty response from server'));
          } else if (typeof global.mvpgToast !== 'undefined') {
            global.mvpgToast.error('Server returned no data.');
          }
          return;
        }
        var head = t.substring(0, 16).toLowerCase();
        if (head.indexOf('<!doctype') === 0 || head.indexOf('<html') === 0) {
          if (typeof onError === 'function') {
            onError(new Error('Server returned HTML instead of XML (session may have expired)'));
          } else if (typeof global.mvpgToast !== 'undefined') {
            global.mvpgToast.error('Session expired or login required — refresh the page.');
          }
          return;
        }
        if (t.charAt(0) === '{') {
          if (typeof onError === 'function') {
            onError(new Error('Server returned JSON instead of XML'));
          } else if (typeof global.mvpgToast !== 'undefined') {
            global.mvpgToast.error('Server error — data unavailable.');
          }
          return;
        }
        var parser = new DOMParser();
        var xmlDoc = parser.parseFromString(raw, 'text/xml');
        if (xmlDoc.getElementsByTagName('parsererror').length > 0) {
          if (typeof onError === 'function') {
            onError(new Error('Invalid XML response'));
          } else if (typeof global.mvpgToast !== 'undefined') {
            global.mvpgToast.error('Invalid response from server.');
          }
          return;
        }
        onSuccess(xmlDoc);
      } else {
        onSuccess(text);
      }
    })
    .catch(function (err) {
      _hideLoading();
      console.error('[mvpg-fetch] Request failed:', err);
      if (typeof onError === 'function') {
        onError(err);
      } else {
        // Default fallback: show a toast if available, otherwise console
        if (typeof mvpgToast !== 'undefined') {
          mvpgToast.error('Network error — please try again.');
        } else {
          console.error('[mvpg-fetch] No error handler provided. Error:', err.message);
        }
      }
    });
  }

  /* ── Public API ────────────────────────────────────────────────── */

  /**
   * Post and receive an XML document.
   * @param {string}   bodyStr   URL-encoded POST body (same as XHR.send(str))
   * @param {function} onSuccess Called with (xmlDocument)
   * @param {function} [onError] Optional error handler called with (Error)
   */
  global.mvpgPostXML = function (bodyStr, onSuccess, onError) {
    _doFetch(bodyStr, 'xml', onSuccess, onError);
  };

  /**
   * Post and receive plain text.
   * @param {string}   bodyStr   URL-encoded POST body
   * @param {function} onSuccess Called with (responseText)
   * @param {function} [onError] Optional error handler called with (Error)
   */
  global.mvpgPostText = function (bodyStr, onSuccess, onError) {
    _doFetch(bodyStr, 'text', onSuccess, onError);
  };

  /**
   * Post and receive a JSON object.
   * @param {string}   bodyStr   URL-encoded POST body
   * @param {function} onSuccess Called with (parsedObject)
   * @param {function} [onError] Optional error handler called with (Error)
   */
  global.mvpgPostJSON = function (bodyStr, onSuccess, onError) {
    _showLoading();
    fetch(resolveServletUrl(), {
      method: 'POST',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
      body: bodyStr
    })
    .then(function (resp) {
      if (!resp.ok) throw new Error('HTTP ' + resp.status);
      return resp.json();
    })
    .then(function (data) {
      _hideLoading();
      onSuccess(data);
    })
    .catch(function (err) {
      _hideLoading();
      console.error('[mvpg-fetch] JSON request failed:', err);
      if (typeof onError === 'function') onError(err);
    });
  };

  /**
   * Convenience: show the loading bar manually (e.g. before a form submit).
   */
  global.mvpgShowLoading = _showLoading;
  global.mvpgHideLoading = _hideLoading;

  /* ── Debounce utility (used by auto-search triggers) ───────────── */
  global.mvpgDebounce = function (fn, delayMs) {
    var timer;
    return function () {
      var ctx = this, args = arguments;
      clearTimeout(timer);
      timer = setTimeout(function () { fn.apply(ctx, args); }, delayMs || 350);
    };
  };

}(window));
