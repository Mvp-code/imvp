/* MVPx — per-user preferences: theme colors, language, accessibility */
(function() {
  'use strict';

  var THEMES = {
    blue:   { accent: '#2563eb', accentLight: '#eff6ff', accentDark: '#1d4ed8' },
    green:  { accent: '#059669', accentLight: '#ecfdf5', accentDark: '#047857' },
    purple: { accent: '#7c3aed', accentLight: '#ede9fe', accentDark: '#6d28d9' },
    slate:  { accent: '#475569', accentLight: '#f1f5f9', accentDark: '#334155' },
    orange: { accent: '#ea580c', accentLight: '#fff7ed', accentDark: '#c2410c' }
  };

  var I18N = {
    en: {
      'Sign Out': 'Sign Out',
      'Filter menu…': 'Filter menu…',
      'Search records…': 'Search records…',
      'Enter': 'Enter',
      'Expand menu': 'Expand menu',
      'Collapse menu': 'Collapse menu',
      'Preferences': 'Preferences',
      'Theme color': 'Theme color',
      'Language': 'Language',
      'Accessibility': 'Accessibility',
      'Larger text': 'Larger text',
      'High contrast': 'High contrast',
      'Reduce motion': 'Reduce motion',
      'English': 'English',
      'Español': 'Español',
      'Skip to content': 'Skip to content',
      'Settings': 'Settings',
      'User': 'User',
      'Operations': 'Operations',
      'People': 'People',
      'Safety & Fleet': 'Safety & Fleet',
      'Documents': 'Documents',
      'Reports': 'Reports',
      'Admin': 'Admin',
      'Home': 'Home',
      'Dashboard': 'Dashboard',
      'DA Confirmations': 'DA Confirmations',
      'DA Checkins': 'DA Checkins',
      'DA Checkouts': 'DA Checkouts',
      'SMS': 'SMS',
      'Employee Info': 'Employee Info',
      'DA Onboarding': 'DA Onboarding',
      'Onboarding Dashboard': 'Onboarding Dashboard',
      'Coaching Followup': 'Coaching Followup',
      'Employee Requests': 'Employee Requests',
      'Employee Uploads': 'Employee Uploads',
      'OSHA Incidents': 'OSHA Incidents',
      'Incident': 'Incident',
      'Vehicle Info': 'Vehicle Info',
      'Uploads': 'Uploads',
      'Smart Upload': 'Smart Upload',
      'Upload History': 'Upload History'
    },
    es: {
      'Sign Out': 'Cerrar sesión',
      'Filter menu…': 'Filtrar menú…',
      'Search records…': 'Buscar registros…',
      'Enter': 'Entrar',
      'Expand menu': 'Expandir menú',
      'Collapse menu': 'Contraer menú',
      'Preferences': 'Preferencias',
      'Theme color': 'Color del tema',
      'Language': 'Idioma',
      'Accessibility': 'Accesibilidad',
      'Larger text': 'Texto más grande',
      'High contrast': 'Alto contraste',
      'Reduce motion': 'Reducir movimiento',
      'English': 'English',
      'Español': 'Español',
      'Skip to content': 'Saltar al contenido',
      'Settings': 'Configuración',
      'User': 'Usuario',
      'Operations': 'Operaciones',
      'People': 'Personal',
      'Safety & Fleet': 'Seguridad y Flota',
      'Documents': 'Documentos',
      'Reports': 'Informes',
      'Admin': 'Administración',
      'Home': 'Inicio',
      'Dashboard': 'Panel',
      'DA Confirmations': 'Confirmaciones DA',
      'DA Checkins': 'Entradas DA',
      'DA Checkouts': 'Salidas DA',
      'SMS': 'SMS',
      'Employee Info': 'Info Empleados',
      'DA Onboarding': 'Incorporación DA',
      'Onboarding Dashboard': 'Panel de Incorporación',
      'Coaching Followup': 'Seguimiento Coaching',
      'Employee Requests': 'Solicitudes Empleados',
      'Employee Uploads': 'Cargas Empleados',
      'OSHA Incidents': 'Incidentes OSHA',
      'Incident': 'Incidente',
      'Vehicle Info': 'Info Vehículos',
      'Uploads': 'Cargas',
      'Smart Upload': 'Carga inteligente',
      'Upload History': 'Historial de cargas'
    }
  };

  function userKey() {
    if (window.MVPX_SERVER_PREFS && window.MVPX_SERVER_PREFS.userKey)
      return window.MVPX_SERVER_PREFS.userKey;
    var el = document.getElementById('mvpxUserKey');
    return (el && el.value) ? el.value : 'default';
  }

  function prefKey(suffix) {
    return 'mvpx_' + suffix + '_' + userKey();
  }

  /* Persist the full preference state to the server (DB-backed).
     Fire-and-forget; localStorage still provides instant/offline behavior. */
  function savePrefsToServer() {
    if (!window.MVPX_CTX) return;
    var entityID = (window.MVPX_SERVER_PREFS && window.MVPX_SERVER_PREFS.entityID) || '';
    var params = 'controller=UserPref'
      + '&userID=' + encodeURIComponent(userKey())
      + '&entityID=' + encodeURIComponent(entityID)
      + '&theme=' + encodeURIComponent(localStorage.getItem(prefKey('theme')) || 'blue')
      + '&lang=' + encodeURIComponent(localStorage.getItem(prefKey('lang')) || 'en')
      + '&fontScale=' + encodeURIComponent(localStorage.getItem(prefKey('fontScale')) || '1')
      + '&a11yLarge=' + (localStorage.getItem(prefKey('a11y_large')) === '1' ? '1' : '0')
      + '&a11yContrast=' + (localStorage.getItem(prefKey('a11y_contrast')) === '1' ? '1' : '0')
      + '&a11yMotion=' + (localStorage.getItem(prefKey('a11y_motion')) === '1' ? '1' : '0');
    try {
      var xhr = new XMLHttpRequest();
      xhr.open('POST', window.MVPX_CTX + '/servlet/APIServlet?' + params, true);
      xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
      xhr.send();
    } catch (e) { /* ignore network errors; localStorage already updated */ }
  }

  function applyTheme(themeId) {
    var t = THEMES[themeId] || THEMES.blue;
    var root = document.documentElement;
    root.setAttribute('data-mvpx-theme', themeId);
    root.style.setProperty('--theme-accent', t.accent);
    root.style.setProperty('--theme-accent-light', t.accentLight);
    root.style.setProperty('--theme-accent-dark', t.accentDark);
    /* Sidebar is dark (navy) — active pill uses translucent accent + white text */
    root.style.setProperty('--sb-active-bg', 'color-mix(in srgb, ' + t.accent + ' 22%, transparent)');
    root.style.setProperty('--sb-active-text', '#ffffff');
    root.style.setProperty('--sb-active-bar', t.accent);
    root.style.setProperty('--blue', t.accent);
    root.style.setProperty('--blue-dark', t.accentDark);
    root.style.setProperty('--blue-light', t.accentLight);
    document.querySelectorAll('.mvpx-theme-swatch').forEach(function(sw) {
      sw.classList.toggle('active', sw.dataset.theme === themeId);
      sw.setAttribute('aria-pressed', sw.dataset.theme === themeId ? 'true' : 'false');
    });
  }

  function applyLang(lang) {
    var dict = I18N[lang] || I18N.en;
    document.documentElement.lang = lang === 'es' ? 'es' : 'en';
    document.querySelectorAll('[data-i18n]').forEach(function(el) {
      var key = el.getAttribute('data-i18n');
      if (dict[key]) {
        if (el.tagName === 'INPUT' && el.placeholder !== undefined) {
          el.placeholder = dict[key];
        } else {
          el.textContent = dict[key];
        }
      }
    });
    document.querySelectorAll('[data-tip]').forEach(function(el) {
      var key = el.getAttribute('data-tip');
      if (dict[key]) el.setAttribute('data-tip', dict[key]);
    });
    var langEn = document.getElementById('mvpxLangEn');
    var langEs = document.getElementById('mvpxLangEs');
    if (langEn) langEn.classList.toggle('active', lang === 'en');
    if (langEs) langEs.classList.toggle('active', lang === 'es');
    if (langEn) langEn.setAttribute('aria-pressed', lang === 'en' ? 'true' : 'false');
    if (langEs) langEs.setAttribute('aria-pressed', lang === 'es' ? 'true' : 'false');
  }

  function applyA11y() {
    var large = localStorage.getItem(prefKey('a11y_large')) === '1';
    var contrast = localStorage.getItem(prefKey('a11y_contrast')) === '1';
    var motion = localStorage.getItem(prefKey('a11y_motion')) === '1';
    document.documentElement.classList.toggle('mvpx-a11y-large', large);
    document.documentElement.classList.toggle('mvpx-a11y-contrast', contrast);
    document.documentElement.classList.toggle('mvpx-a11y-reduce-motion', motion);
    var cbLarge = document.getElementById('mvpxA11yLarge');
    var cbContrast = document.getElementById('mvpxA11yContrast');
    var cbMotion = document.getElementById('mvpxA11yMotion');
    if (cbLarge) cbLarge.checked = large;
    if (cbContrast) cbContrast.checked = contrast;
    if (cbMotion) cbMotion.checked = motion;
  }

  window.mvpxSetTheme = function(themeId) {
    localStorage.setItem(prefKey('theme'), themeId);
    applyTheme(themeId);
    savePrefsToServer();
  };

  window.mvpxSetLang = function(lang) {
    localStorage.setItem(prefKey('lang'), lang);
    applyLang(lang);
    savePrefsToServer();
    var sb = document.getElementById('mvpxSbToggle');
    if (sb && typeof mvpxUpdateCollapseIcon === 'function') {
      var expanded = document.getElementById('mvpxSidebar') &&
        !document.getElementById('mvpxSidebar').classList.contains('collapsed');
      sb.title = expanded
        ? (I18N[lang] || I18N.en)['Collapse menu']
        : (I18N[lang] || I18N.en)['Expand menu'];
    }
  };

  window.mvpxTogglePrefs = function() {
    var panel = document.getElementById('mvpxPrefsPanel');
    var backdrop = document.getElementById('mvpxPrefsBackdrop');
    if (!panel) return;
    var open = panel.classList.toggle('open');
    if (backdrop) backdrop.classList.toggle('visible', open);
    panel.setAttribute('aria-hidden', open ? 'false' : 'true');
    if (open) {
      var first = panel.querySelector('button, input');
      if (first) first.focus();
    }
  };

  window.mvpxClosePrefs = function() {
    var panel = document.getElementById('mvpxPrefsPanel');
    var backdrop = document.getElementById('mvpxPrefsBackdrop');
    if (panel) { panel.classList.remove('open'); panel.setAttribute('aria-hidden', 'true'); }
    if (backdrop) backdrop.classList.remove('visible');
  };

  window.mvpxToggleA11y = function(key, checked) {
    localStorage.setItem(prefKey('a11y_' + key), checked ? '1' : '0');
    applyA11y();
    savePrefsToServer();
  };

  /* On load, the DB values (rendered by the server) are the source of truth.
     Seed localStorage from them so every browser/device reflects the saved
     preferences; if none were provided, fall back to whatever is local. */
  function seedFromServer() {
    var sp = window.MVPX_SERVER_PREFS;
    if (!sp) return;
    if (sp.theme) localStorage.setItem(prefKey('theme'), sp.theme);
    if (sp.lang) localStorage.setItem(prefKey('lang'), sp.lang);
    if (sp.fontScale) localStorage.setItem(prefKey('fontScale'), sp.fontScale);
    localStorage.setItem(prefKey('a11y_large'), sp.a11yLarge ? '1' : '0');
    localStorage.setItem(prefKey('a11y_contrast'), sp.a11yContrast ? '1' : '0');
    localStorage.setItem(prefKey('a11y_motion'), sp.a11yMotion ? '1' : '0');
  }

  window.mvpxInitPrefs = function() {
    seedFromServer();
    applyTheme(localStorage.getItem(prefKey('theme')) || 'blue');
    applyLang(localStorage.getItem(prefKey('lang')) || 'en');
    applyA11y();
  };

  document.addEventListener('DOMContentLoaded', function() {
    mvpxInitPrefs();
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape') mvpxClosePrefs();
    });
  });
})();
