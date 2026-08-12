var API_BASE_URL = document.body.getAttribute('data-api-url') || '';

(function() {
  var meta = document.querySelector('meta[name="api-base-url"]');
  if (meta) {
    API_BASE_URL = meta.getAttribute('content');
  } else {
    var host = window.location.hostname;
    var port = (host === 'localhost' || host === '127.0.0.1') ? ':5000' : '';
    API_BASE_URL = window.location.protocol + '//' + host + port;
  }
  if (!API_BASE_URL || API_BASE_URL === '/') {
    API_BASE_URL = window.location.protocol + '//' + window.location.hostname + ':5000';
  }
  API_BASE_URL = API_BASE_URL.replace(/\/+$/, '');
  console.log('API Base URL:', API_BASE_URL);
})();

function apiFetch(endpoint, options) {
  var url = API_BASE_URL + '/api/' + endpoint;
  return fetch(url, options).then(function(r) {
    if (!r.ok) throw new Error('HTTP ' + r.status);
    return r.json();
  });
}