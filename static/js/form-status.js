(function () {
  var SUCCESS_MSG = '__FORM_SUCCESS_MSG__';
  var ERROR_MSG = '__FORM_ERROR_MSG__';

  var params = new URLSearchParams(window.location.search);
  var status = params.get('form-status');

  if (status !== 'success' && status !== 'error') return;

  var cleanUrl = new URL(window.location.href);
  cleanUrl.searchParams.delete('form-status');
  history.replaceState(null, '', cleanUrl.toString());

  var isSuccess = status === 'success';
  var accentColor = isSuccess ? '#22c55e' : '#ff4d4d';
  var title = isSuccess ? 'Pedido enviado!' : 'Algo correu mal';
  var msg = isSuccess ? SUCCESS_MSG : ERROR_MSG;

  var overlay = document.createElement('div');
  overlay.style.cssText = [
    'position:fixed','inset:0','z-index:99999','display:flex',
    'align-items:center','justify-content:center','background:rgba(0,0,0,0.72)',
    'backdrop-filter:blur(4px)','-webkit-backdrop-filter:blur(4px)',
    'font-family:sans-serif','padding:24px','box-sizing:border-box',
  ].join(';');

  var card = document.createElement('div');
  card.style.cssText = [
    'position:relative','background:#0d0d0d','border:1px solid #272727',
    'border-radius:16px','max-width:480px','width:100%','padding:40px 36px',
    'text-align:center','box-shadow:0 24px 64px rgba(0,0,0,0.6)','box-sizing:border-box',
  ].join(';');

  var closeBtn = document.createElement('button');
  closeBtn.innerHTML = '&times;';
  closeBtn.style.cssText = [
    'position:absolute','top:16px','right:16px','background:none','border:none',
    'color:#666','font-size:24px','line-height:1','cursor:pointer','padding:4px 8px',
  ].join(';');

  var icon = document.createElement('div');
  icon.style.cssText = [
    'width:64px','height:64px','border-radius:50%','border:2px solid ' + accentColor,
    'display:flex','align-items:center','justify-content:center','margin:0 auto 24px',
    'font-size:28px','color:' + accentColor,
  ].join(';');
  icon.textContent = isSuccess ? '✓' : '✕';

  var titleEl = document.createElement('h3');
  titleEl.textContent = title;
  titleEl.style.cssText = ['color:#fff','font-size:22px','font-weight:700','margin:0 0 12px'].join(';');

  var msgEl = document.createElement('p');
  msgEl.textContent = msg;
  msgEl.style.cssText = ['color:#bbb','font-size:15px','line-height:1.6','margin:0 0 28px'].join(';');

  var ctaBtn = document.createElement('button');
  ctaBtn.textContent = 'Fechar';
  ctaBtn.style.cssText = [
    'background:' + accentColor,'color:' + (isSuccess ? '#0d0d0d' : '#fff'),
    'border:none','border-radius:8px','font-size:15px','font-weight:600',
    'padding:12px 32px','cursor:pointer','width:100%',
  ].join(';');

  function close() { overlay.remove(); }
  closeBtn.addEventListener('click', close);
  ctaBtn.addEventListener('click', close);
  overlay.addEventListener('click', function (e) { if (e.target === overlay) close(); });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') close(); });

  card.appendChild(closeBtn);
  card.appendChild(icon);
  card.appendChild(titleEl);
  card.appendChild(msgEl);
  card.appendChild(ctaBtn);
  overlay.appendChild(card);

  function mount() { document.body.appendChild(overlay); }
  if (document.body) { mount(); } else { document.addEventListener('DOMContentLoaded', mount); }
})();
