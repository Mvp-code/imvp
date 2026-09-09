/* ═══════════════════════════════════════════════════════════════
   MVPx Core JavaScript
   ═══════════════════════════════════════════════════════════════ */

// ── Sidebar toggle ───────────────────────────────────────────
function mvpxToggleSidebar() {
  const sb = document.getElementById('mvpxSidebar');
  const backdrop = document.getElementById('sbBackdrop');
  if (!sb) return;

  if (window.innerWidth <= 768) {
    sb.classList.toggle('mobile-open');
    if (backdrop) backdrop.classList.toggle('visible', sb.classList.contains('mobile-open'));
  } else {
    sb.classList.toggle('collapsed');
    const expanded = !sb.classList.contains('collapsed');
    localStorage.setItem('mvpx_sb_expanded', expanded ? '1' : '0');
    sb.setAttribute('aria-expanded', expanded ? 'true' : 'false');
    mvpxUpdateCollapseIcon();
    var btn = document.getElementById('mvpxSbToggle');
    var mobileBtn = document.getElementById('mobileToggle');
    if (btn) {
      btn.title = expanded ? 'Collapse menu' : 'Expand menu';
      btn.setAttribute('aria-expanded', expanded ? 'true' : 'false');
    }
    if (mobileBtn) mobileBtn.setAttribute('aria-expanded', expanded ? 'true' : 'false');
  }
}

function mvpxCloseMobileSidebar() {
  const sb = document.getElementById('mvpxSidebar');
  const backdrop = document.getElementById('sbBackdrop');
  if (sb) sb.classList.remove('mobile-open');
  if (backdrop) backdrop.classList.remove('visible');
}

function mvpxUpdateCollapseIcon() {
  const btn = document.getElementById('mvpxSbToggle');
  const sb = document.getElementById('mvpxSidebar');
  if (!btn || !sb) return;
  const icon = btn.querySelector('i');
  if (!icon) return;
  icon.className = 'fas fa-bars';
  const mobileBtn = document.getElementById('mobileToggle');
  if (mobileBtn) {
    const mi = mobileBtn.querySelector('i');
    if (mi) mi.className = 'fas fa-bars';
  }
}

function mvpxInitSidebar() {
  const sb = document.getElementById('mvpxSidebar');
  if (!sb) return;
  if (window.innerWidth > 768) {
    if (localStorage.getItem('mvpx_sb_expanded') === '1') {
      sb.classList.remove('collapsed');
    } else {
      sb.classList.add('collapsed');
    }
  }
  sb.setAttribute('aria-expanded', sb.classList.contains('collapsed') ? 'false' : 'true');
  mvpxUpdateCollapseIcon();
  mvpxSyncNavTooltips();
  var btn = document.getElementById('mvpxSbToggle');
  var mobileBtn = document.getElementById('mobileToggle');
  if (btn) {
    btn.title = sb.classList.contains('collapsed') ? 'Expand menu' : 'Collapse menu';
    btn.setAttribute('aria-expanded', sb.classList.contains('collapsed') ? 'false' : 'true');
  }
  if (mobileBtn) mobileBtn.setAttribute('aria-expanded', sb.classList.contains('collapsed') ? 'false' : 'true');
}

function mvpxSyncNavTooltips() {
  document.querySelectorAll('.mvpx-sidebar .sb-item').forEach(function(item) {
    if (item.getAttribute('data-tip')) return;
    var label = item.querySelector('.sb-label');
    if (label && label.textContent.trim()) {
      item.setAttribute('data-tip', label.textContent.trim());
    }
  });
}

// ── Nav groups (accordion) ───────────────────────────────────
function mvpxToggleGroup(headerBtn) {
  const sb = document.getElementById('mvpxSidebar');
  if (sb && sb.classList.contains('collapsed')) return;

  const group = headerBtn.closest('.sb-group');
  if (!group) return;
  group.classList.toggle('open');

  const key = group.dataset.group;
  if (key) {
    const state = {};
    try {
      Object.assign(state, JSON.parse(localStorage.getItem('mvpx_nav_groups') || '{}'));
    } catch (e) { /* ignore */ }
    state[key] = group.classList.contains('open');
    localStorage.setItem('mvpx_nav_groups', JSON.stringify(state));
  }
}

function mvpxInitNavGroups() {
  let saved = {};
  try {
    saved = JSON.parse(localStorage.getItem('mvpx_nav_groups') || '{}');
  } catch (e) { /* ignore */ }

  document.querySelectorAll('.sb-group').forEach(function(group) {
    const hasActive = group.querySelector('.sb-item.active');
    if (hasActive) {
      group.classList.add('open');
      group.classList.add('has-active');
    } else if (group.dataset.group && saved[group.dataset.group] === true) {
      group.classList.add('open');
    } else if (group.dataset.group && saved[group.dataset.group] === false) {
      group.classList.remove('open');
    }
  });
}

function mvpxToggleSubmenu(parentBtn) {
  const sb = document.getElementById('mvpxSidebar');
  if (sb && sb.classList.contains('collapsed')) {
    sb.classList.remove('collapsed');
    localStorage.setItem('mvpx_sb_expanded', '1');
    mvpxUpdateCollapseIcon();
    var btn = document.getElementById('mvpxSbToggle');
    if (btn) btn.title = 'Collapse menu';
  }
  parentBtn.classList.toggle('open');
  const sub = parentBtn.nextElementSibling;
  if (sub && sub.classList.contains('sb-submenu')) {
    sub.classList.toggle('open');
  }
}

// ── Nav filter (sidebar menu search) ─────────────────────────
function mvpxFilterNav(query) {
  const q = (query || '').trim().toLowerCase();
  const scroll = document.getElementById('sbNavScroll');
  if (!scroll) return;

  scroll.querySelectorAll('.sb-sec').forEach(function(sec) {
    let anyVisible = false;
    let el = sec.nextElementSibling;
    while (el && !el.classList.contains('sb-sec')) {
      if (el.classList.contains('sb-submenu-wrap')) {
        let subAny = false;
        el.querySelectorAll('.sb-sub-item').forEach(function(item) {
          const text = (item.textContent || '').toLowerCase();
          const show = !q || text.includes(q);
          item.style.display = show ? '' : 'none';
          if (show) subAny = true;
        });
        const parentLabel = (el.querySelector('.sb-has-sub .sb-label') || {}).textContent || '';
        const parentMatch = q && parentLabel.toLowerCase().includes(q);
        if (parentMatch) {
          el.querySelectorAll('.sb-sub-item').forEach(function(item) { item.style.display = ''; });
          subAny = true;
        }
        el.style.display = (!q || subAny) ? '' : 'none';
        if (subAny) {
          anyVisible = true;
          if (q) {
            el.querySelector('.sb-has-sub').classList.add('open');
            var sub = el.querySelector('.sb-submenu');
            if (sub) sub.classList.add('open');
          }
        }
      } else {
        const label = (el.querySelector('.sb-label') || {}).textContent || el.textContent || '';
        const show = !q || label.toLowerCase().includes(q);
        el.style.display = show ? '' : 'none';
        if (show) anyVisible = true;
      }
      el = el.nextElementSibling;
    }
    sec.style.display = (!q || anyVisible) ? '' : 'none';
  });
}

// ── On-Enter search (applies to every input with data-search) ─
function mvpxInitSearch() {
  document.querySelectorAll('[data-search]').forEach(function(input) {
    input.addEventListener('keydown', function(e) {
      if (e.key !== 'Enter') return;
      e.preventDefault();
      const submitType = input.dataset.submitType || '10';
      const controller = input.dataset.controller || '';
      if (typeof submitPageDataForm === 'function') {
        submitPageDataForm(submitType, controller);
      } else {
        const form = document.getElementById('formmain') || document.querySelector('form');
        if (form) form.submit();
      }
    });
  });

  document.querySelectorAll('.mvpx-search input').forEach(function(input) {
    if (input.dataset.searchWired) return;
    input.dataset.searchWired = 'true';
    input.addEventListener('keydown', function(e) {
      if (e.key !== 'Enter') return;
      e.preventDefault();
      const controller = input.dataset.controller || '';
      const submitType = input.dataset.submitType || '10';
      if (typeof submitPageDataForm === 'function') {
        submitPageDataForm(submitType, controller);
      }
    });
  });
}

// ── Active sidebar item ──────────────────────────────────────
function mvpxSetActiveNav(controller) {
  document.querySelectorAll('.sb-item').forEach(function(el) {
    el.classList.remove('active');
    if (el.dataset.controller && el.dataset.controller === controller) {
      el.classList.add('active');
      const group = el.closest('.sb-group');
      if (group) {
        group.classList.add('open');
        group.classList.add('has-active');
      }
    }
  });
}

// ── Status dots (call with current counts) ───────────────────
function mvpxSetDot(id, level) {
  const el = document.getElementById(id);
  if (!el) return;
  el.className = 'sb-dot ' + (level || '');
  el.style.display = level ? '' : 'none';
}

// ── Mobile overlay close ─────────────────────────────────────
function mvpxInitMobileOverlay() {
  document.addEventListener('click', function(e) {
    const sb = document.getElementById('mvpxSidebar');
    if (!sb || window.innerWidth > 768) return;
    if (sb.classList.contains('mobile-open') && !sb.contains(e.target)) {
      const toggle = document.getElementById('mobileToggle');
      if (toggle && toggle.contains(e.target)) return;
      mvpxCloseMobileSidebar();
    }
  });

  window.addEventListener('resize', function() {
    if (window.innerWidth > 768) mvpxCloseMobileSidebar();
  });
}

// ── Filter chips ─────────────────────────────────────────────
function mvpxInitChips() {
  document.querySelectorAll('.filter-chips').forEach(function(group) {
    group.querySelectorAll('.chip').forEach(function(chip) {
      chip.addEventListener('click', function() {
        group.querySelectorAll('.chip').forEach(function(c) { c.classList.remove('active'); });
        chip.classList.add('active');
        const filter = chip.dataset.filter;
        if (filter) mvpxFilterTable(group, filter);
      });
    });
  });
}

function mvpxFilterTable(chipsEl, filter) {
  const tableId = chipsEl.dataset.table;
  if (!tableId) return;
  const table = document.getElementById(tableId);
  if (!table) return;
  table.querySelectorAll('tbody tr').forEach(function(row) {
    if (filter === 'all') { row.style.display = ''; return; }
    const status = (row.dataset.status || '').toLowerCase();
    row.style.display = status.includes(filter.toLowerCase()) ? '' : 'none';
  });
}

// ── Modal helpers ────────────────────────────────────────────
function mvpxOpenModal(id) {
  const el = document.getElementById(id);
  if (el) el.classList.add('open');
}
function mvpxCloseModal(id) {
  const el = document.getElementById(id);
  if (el) el.classList.remove('open');
}

// ── Toast notification ───────────────────────────────────────
function mvpxToast(message, type) {
  type = type || 'info';
  const toast = document.createElement('div');
  toast.className = 'alert alert-' + type;
  toast.style.cssText = 'position:fixed;bottom:20px;right:20px;z-index:9999;min-width:260px;max-width:400px;box-shadow:0 4px 16px rgba(0,0,0,.15);animation:fadeIn .2s ease';
  toast.textContent = message;
  document.body.appendChild(toast);
  setTimeout(function() { toast.remove(); }, 3500);
}

// ── Init all on DOM ready ────────────────────────────────────
document.addEventListener('DOMContentLoaded', function() {
  mvpxInitSidebar();
  mvpxInitNavGroups();
  mvpxInitSearch();
  mvpxInitMobileOverlay();
  mvpxInitChips();
});
