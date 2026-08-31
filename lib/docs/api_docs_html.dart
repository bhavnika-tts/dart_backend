import 'dart:convert';
import 'api_catalog.dart';

/// Generates interactive, modern HTML documentation for the backend API.
class ApiDocsRenderer {
  static String render() {
    const endpoints = ApiCatalog.endpoints;
    final totalCount = endpoints.length;

    final categories = <String>{};
    for (final ep in endpoints) {
      categories.add(ep.category);
    }

    final quickNavItems = StringBuffer();
    final apiCards = StringBuffer();

    for (final ep in endpoints) {
      final methodClass = ep.method.toLowerCase();
      final targetId = 'api-${ep.index}';

      // Quick Nav Item
      quickNavItems.write('''
        <a href="#$targetId" class="nav-chip method-$methodClass" data-category="${ep.category}" data-method="${ep.method}">
          <span class="nav-idx">${ep.formattedIndex}</span>
          <span class="nav-method">${ep.method}</span>
          <span class="nav-path">${ep.path}</span>
        </a>
      ''');

      // Parameters block
      final paramsBuffer = StringBuffer();
      if (ep.pathParams.isNotEmpty) {
        paramsBuffer.write('<div class="param-section"><h4>Path Parameters</h4><table class="param-table"><tr><th>Param</th><th>Example</th></tr>');
        for (final entry in ep.pathParams.entries) {
          paramsBuffer.write('<tr><td><code>${entry.key}</code></td><td>${entry.value}</td></tr>');
        }
        paramsBuffer.write('</table></div>');
      }

      if (ep.queryParams.isNotEmpty) {
        paramsBuffer.write('<div class="param-section"><h4>Query Parameters</h4><table class="param-table"><tr><th>Query</th><th>Example</th></tr>');
        for (final entry in ep.queryParams.entries) {
          paramsBuffer.write('<tr><td><code>${entry.key}</code></td><td>${entry.value}</td></tr>');
        }
        paramsBuffer.write('</table></div>');
      }

      if (ep.headers.isNotEmpty) {
        paramsBuffer.write('<div class="param-section"><h4>Headers</h4><table class="param-table"><tr><th>Header</th><th>Value</th></tr>');
        for (final entry in ep.headers.entries) {
          paramsBuffer.write('<tr><td><code>${entry.key}</code></td><td>${entry.value}</td></tr>');
        }
        paramsBuffer.write('</table></div>');
      }

      // Request Body
      final reqBodyBlock = ep.requestBody != null
          ? '''
          <div class="body-block">
            <div class="block-header">
              <span>Request Body ${ep.isMultipart ? '(Multipart/Form-Data)' : '(JSON)'}</span>
            </div>
            <pre><code>${htmlEscape.convert(ep.requestBody!)}</code></pre>
          </div>
          '''
          : '';

      // Response Body
      final respBodyBlock = '''
        <div class="body-block">
          <div class="block-header">
            <span>Response Status: <strong class="status-badge status-${ep.responseStatus}">${ep.responseStatus}</strong></span>
          </div>
          <pre><code>${htmlEscape.convert(ep.responseBody)}</code></pre>
        </div>
      ''';

      // Full Card
      apiCards.write('''
        <div class="api-card" id="$targetId" data-category="${ep.category}" data-method="${ep.method}" data-text="${ep.title} ${ep.path} ${ep.description} ${ep.category}">
          <div class="card-top">
            <div class="card-meta">
              <span class="index-badge">${ep.formattedIndex}</span>
              <span class="method-badge method-$methodClass">${ep.method}</span>
              <span class="path-text">${ep.path}</span>
            </div>
            <div class="card-tags">
              <span class="category-tag">${ep.category}</span>
              ${ep.requiresAdmin ? '<span class="auth-tag admin">Admin Only</span>' : ep.requiresAuth ? '<span class="auth-tag user">Requires JWT</span>' : '<span class="auth-tag public">Public</span>'}
            </div>
          </div>
          <div class="card-body">
            <h3 class="api-title">${ep.title}</h3>
            <p class="api-desc">${ep.description}</p>
            
            $paramsBuffer
            
            <div class="code-grid">
              ${reqBodyBlock.isNotEmpty ? reqBodyBlock : ''}
              $respBodyBlock
            </div>

            <div class="curl-section">
              <div class="curl-header">
                <span>cURL Request Example</span>
                <button class="copy-btn" onclick="copyCurl(this, '${ep.index}')">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>
                  Copy cURL
                </button>
              </div>
              <pre><code id="curl-${ep.index}">${htmlEscape.convert(ep.curlExample)}</code></pre>
            </div>
          </div>
        </div>
      ''');
    }

    final categoryFilterChips = StringBuffer()
      ..write('<button class="filter-chip active" onclick="filterCategory(\'ALL\', this)">All Categories</button>');
    for (final cat in categories) {
      categoryFilterChips.write('<button class="filter-chip" onclick="filterCategory(\'$cat\', this)">$cat</button>');
    }

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Classicale API Documentation Explorer</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Fira+Code:wght@400;500;600&family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg-main: #090d16;
      --bg-surface: #111827;
      --bg-surface-elevated: #1e293b;
      --bg-card: #0f172a;
      --border-color: #334155;
      --border-light: rgba(255, 255, 255, 0.08);
      --text-main: #f8fafc;
      --text-muted: #94a3b8;
      --text-dim: #64748b;
      --primary: #6366f1;
      --primary-hover: #4f46e5;
      --primary-glow: rgba(99, 102, 241, 0.18);
      
      --color-get: #10b981;
      --color-get-bg: rgba(16, 185, 129, 0.12);
      --color-post: #3b82f6;
      --color-post-bg: rgba(59, 130, 246, 0.12);
      --color-put: #f59e0b;
      --color-put-bg: rgba(245, 158, 11, 0.12);
      --color-delete: #ef4444;
      --color-delete-bg: rgba(239, 68, 68, 0.12);
      --color-patch: #a855f7;
      --color-patch-bg: rgba(168, 85, 247, 0.12);
    }

    * { box-sizing: border-box; margin: 0; padding: 0; }
    html { scroll-behavior: smooth; }
    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
      background-color: var(--bg-main);
      color: var(--text-main);
      line-height: 1.5;
      padding: 0;
      margin: 0;
    }

    /* Container */
    .app-container {
      max-width: 1300px;
      margin: 0 auto;
      padding: 2rem 1.5rem 6rem;
    }

    /* Hero Header */
    .hero-header {
      background: linear-gradient(135deg, rgba(30, 41, 59, 0.7) 0%, rgba(15, 23, 42, 0.9) 100%);
      border: 1px solid var(--border-light);
      border-radius: 16px;
      padding: 2.5rem 2rem;
      margin-bottom: 2rem;
      box-shadow: 0 10px 30px rgba(0, 0, 0, 0.35);
      position: relative;
      overflow: hidden;
    }
    .hero-header::before {
      content: "";
      position: absolute;
      top: -50%;
      right: -20%;
      width: 400px;
      height: 400px;
      background: radial-gradient(circle, rgba(99, 102, 241, 0.15) 0%, transparent 70%);
      pointer-events: none;
    }
    .hero-title {
      font-size: 2.25rem;
      font-weight: 800;
      letter-spacing: -0.025em;
      background: linear-gradient(90deg, #ffffff, #93c5fd, #a5b4fc);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      margin-bottom: 0.5rem;
    }
    .hero-subtitle {
      color: var(--text-muted);
      font-size: 1.05rem;
      max-width: 800px;
      margin-bottom: 1.5rem;
    }
    .stats-row {
      display: flex;
      flex-wrap: wrap;
      gap: 1.25rem;
    }
    .stat-badge {
      background: rgba(15, 23, 42, 0.7);
      border: 1px solid var(--border-light);
      border-radius: 10px;
      padding: 0.6rem 1.2rem;
      display: flex;
      align-items: center;
      gap: 0.6rem;
      font-size: 0.875rem;
    }
    .stat-badge .stat-num {
      font-weight: 700;
      color: #38bdf8;
      font-size: 1.05rem;
    }
    .stat-badge .pulse-dot {
      width: 8px;
      height: 8px;
      background-color: #10b981;
      border-radius: 50%;
      box-shadow: 0 0 8px #10b981;
      animation: pulse 2s infinite;
    }
    @keyframes pulse {
      0% { transform: scale(0.95); opacity: 0.7; }
      50% { transform: scale(1.2); opacity: 1; }
      100% { transform: scale(0.95); opacity: 0.7; }
    }

    /* Jump to Index Section */
    .jump-section {
      background: var(--bg-surface);
      border: 1px solid var(--border-color);
      border-radius: 14px;
      padding: 1.5rem;
      margin-bottom: 2rem;
      box-shadow: 0 4px 20px rgba(0,0,0,0.2);
    }
    .section-title {
      font-size: 1.15rem;
      font-weight: 700;
      margin-bottom: 1rem;
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }
    .quick-index-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
      gap: 0.5rem;
      max-height: 280px;
      overflow-y: auto;
      padding-right: 0.5rem;
    }
    .quick-index-grid::-webkit-scrollbar {
      width: 6px;
    }
    .quick-index-grid::-webkit-scrollbar-thumb {
      background: var(--border-color);
      border-radius: 4px;
    }
    .nav-chip {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      background: rgba(15, 23, 42, 0.6);
      border: 1px solid var(--border-light);
      border-radius: 6px;
      padding: 0.4rem 0.6rem;
      text-decoration: none;
      color: var(--text-main);
      font-size: 0.8rem;
      transition: all 0.15s ease;
      overflow: hidden;
      white-space: nowrap;
    }
    .nav-chip:hover {
      background: var(--bg-surface-elevated);
      border-color: var(--primary);
      transform: translateY(-1px);
    }
    .nav-idx {
      font-family: 'Fira Code', monospace;
      font-weight: 700;
      color: #38bdf8;
      font-size: 0.75rem;
    }
    .nav-method {
      font-weight: 700;
      font-size: 0.7rem;
      padding: 0.15rem 0.35rem;
      border-radius: 4px;
      text-transform: uppercase;
    }
    .nav-path {
      font-family: 'Fira Code', monospace;
      color: var(--text-muted);
      overflow: hidden;
      text-overflow: ellipsis;
    }

    /* Controls Bar: Search & Filters */
    .controls-bar {
      display: flex;
      flex-direction: column;
      gap: 1rem;
      margin-bottom: 2rem;
      position: sticky;
      top: 1rem;
      z-index: 100;
      background: rgba(9, 13, 22, 0.92);
      backdrop-filter: blur(12px);
      padding: 1rem;
      border-radius: 12px;
      border: 1px solid var(--border-color);
      box-shadow: 0 10px 25px rgba(0, 0, 0, 0.4);
    }
    .search-input-wrapper {
      position: relative;
      width: 100%;
    }
    .search-input {
      width: 100%;
      background: var(--bg-surface);
      border: 1px solid var(--border-color);
      border-radius: 8px;
      padding: 0.75rem 1rem 0.75rem 2.5rem;
      color: var(--text-main);
      font-size: 0.95rem;
      outline: none;
      transition: border-color 0.2s;
    }
    .search-input:focus {
      border-color: var(--primary);
      box-shadow: 0 0 0 2px var(--primary-glow);
    }
    .search-icon {
      position: absolute;
      left: 0.85rem;
      top: 50%;
      transform: translateY(-50%);
      color: var(--text-dim);
    }
    .filter-chips-row {
      display: flex;
      flex-wrap: wrap;
      gap: 0.5rem;
      align-items: center;
    }
    .filter-chip {
      background: var(--bg-surface);
      border: 1px solid var(--border-color);
      color: var(--text-muted);
      padding: 0.35rem 0.75rem;
      border-radius: 20px;
      font-size: 0.8rem;
      font-weight: 500;
      cursor: pointer;
      transition: all 0.15s;
    }
    .filter-chip:hover {
      background: var(--bg-surface-elevated);
      color: var(--text-main);
    }
    .filter-chip.active {
      background: var(--primary);
      color: #ffffff;
      border-color: var(--primary);
    }

    /* Method specific colors */
    .method-get { color: var(--color-get); background: var(--color-get-bg); border: 1px solid rgba(16, 185, 129, 0.3); }
    .method-post { color: var(--color-post); background: var(--color-post-bg); border: 1px solid rgba(59, 130, 246, 0.3); }
    .method-put { color: var(--color-put); background: var(--color-put-bg); border: 1px solid rgba(245, 158, 11, 0.3); }
    .method-delete { color: var(--color-delete); background: var(--color-delete-bg); border: 1px solid rgba(239, 68, 68, 0.3); }
    .method-patch { color: var(--color-patch); background: var(--color-patch-bg); border: 1px solid rgba(168, 85, 247, 0.3); }

    /* API Cards */
    .api-card {
      background: var(--bg-card);
      border: 1px solid var(--border-color);
      border-radius: 12px;
      margin-bottom: 1.5rem;
      overflow: hidden;
      transition: border-color 0.2s, box-shadow 0.2s;
    }
    .api-card:hover {
      border-color: #475569;
      box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
    }
    .card-top {
      display: flex;
      justify-content: space-between;
      align-items: center;
      background: var(--bg-surface);
      padding: 0.9rem 1.25rem;
      border-bottom: 1px solid var(--border-color);
      flex-wrap: wrap;
      gap: 0.75rem;
    }
    .card-meta {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      flex-wrap: wrap;
    }
    .index-badge {
      font-family: 'Fira Code', monospace;
      font-weight: 800;
      color: #38bdf8;
      font-size: 0.95rem;
      background: rgba(56, 189, 248, 0.12);
      padding: 0.2rem 0.5rem;
      border-radius: 4px;
      border: 1px solid rgba(56, 189, 248, 0.25);
    }
    .method-badge {
      font-weight: 800;
      font-size: 0.75rem;
      padding: 0.25rem 0.55rem;
      border-radius: 6px;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
    .path-text {
      font-family: 'Fira Code', monospace;
      font-weight: 600;
      color: var(--text-main);
      font-size: 0.95rem;
    }
    .card-tags {
      display: flex;
      gap: 0.5rem;
      align-items: center;
    }
    .category-tag {
      background: rgba(255, 255, 255, 0.06);
      border: 1px solid var(--border-light);
      font-size: 0.75rem;
      padding: 0.2rem 0.5rem;
      border-radius: 4px;
      color: var(--text-muted);
    }
    .auth-tag {
      font-size: 0.75rem;
      padding: 0.2rem 0.5rem;
      border-radius: 4px;
      font-weight: 600;
    }
    .auth-tag.public { background: rgba(16, 185, 129, 0.15); color: #34d399; }
    .auth-tag.user { background: rgba(59, 130, 246, 0.15); color: #60a5fa; }
    .auth-tag.admin { background: rgba(239, 68, 68, 0.15); color: #f87171; }

    .card-body {
      padding: 1.25rem;
    }
    .api-title {
      font-size: 1.15rem;
      font-weight: 700;
      margin-bottom: 0.35rem;
    }
    .api-desc {
      color: var(--text-muted);
      font-size: 0.9rem;
      margin-bottom: 1rem;
    }

    /* Params Table */
    .param-section {
      margin-bottom: 1rem;
    }
    .param-section h4 {
      font-size: 0.8rem;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: var(--text-dim);
      margin-bottom: 0.4rem;
    }
    .param-table {
      width: 100%;
      border-collapse: collapse;
      font-size: 0.85rem;
      background: rgba(15, 23, 42, 0.5);
      border-radius: 6px;
      overflow: hidden;
    }
    .param-table th, .param-table td {
      padding: 0.45rem 0.75rem;
      text-align: left;
      border-bottom: 1px solid var(--border-light);
    }
    .param-table th {
      color: var(--text-dim);
      font-weight: 600;
      font-size: 0.75rem;
    }
    .param-table code {
      font-family: 'Fira Code', monospace;
      color: #e2e8f0;
      background: rgba(255, 255, 255, 0.06);
      padding: 0.1rem 0.3rem;
      border-radius: 4px;
    }

    /* Code Grid */
    .code-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
      gap: 1rem;
      margin-bottom: 1rem;
    }
    .body-block {
      background: #090d16;
      border: 1px solid var(--border-color);
      border-radius: 8px;
      overflow: hidden;
    }
    .block-header {
      background: rgba(30, 41, 59, 0.5);
      padding: 0.45rem 0.75rem;
      font-size: 0.75rem;
      font-weight: 600;
      color: var(--text-muted);
      border-bottom: 1px solid var(--border-color);
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .status-badge {
      padding: 0.1rem 0.4rem;
      border-radius: 4px;
      font-size: 0.75rem;
    }
    .status-200, .status-201 { background: rgba(16, 185, 129, 0.2); color: #34d399; }
    .status-400, .status-401, .status-404 { background: rgba(239, 68, 68, 0.2); color: #f87171; }

    pre {
      padding: 0.75rem;
      margin: 0;
      overflow-x: auto;
      font-family: 'Fira Code', monospace;
      font-size: 0.8rem;
      line-height: 1.4;
      color: #cbd5e1;
    }

    /* cURL Section */
    .curl-section {
      background: #020617;
      border: 1px solid #1e293b;
      border-radius: 8px;
      overflow: hidden;
    }
    .curl-header {
      background: #0f172a;
      padding: 0.45rem 0.75rem;
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 0.75rem;
      color: var(--text-dim);
      font-weight: 600;
      border-bottom: 1px solid #1e293b;
    }
    .copy-btn {
      background: var(--bg-surface-elevated);
      border: 1px solid var(--border-color);
      color: var(--text-main);
      border-radius: 4px;
      padding: 0.2rem 0.5rem;
      font-size: 0.75rem;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 0.35rem;
      transition: all 0.15s;
    }
    .copy-btn:hover {
      background: var(--primary);
      border-color: var(--primary);
    }
  </style>
</head>
<body>

<div class="app-container">

  <!-- Hero Header -->
  <header class="hero-header">
    <h1 class="hero-title">Classicale Backend API Explorer</h1>
    <p class="hero-subtitle">Interactive documentation, live index navigator, request headers, JSON payloads, and ready-to-copy cURL requests for all Dart backend services.</p>
    <div class="stats-row">
      <div class="stat-badge">
        <span class="pulse-dot"></span>
        <span>Status: <strong>Online (Dart Frog)</strong></span>
      </div>
      <div class="stat-badge">
        <span>Total Endpoints: <span class="stat-num">$totalCount</span></span>
      </div>
      <div class="stat-badge">
        <span>Response Parity: <strong>100% Exact Copy</strong></span>
      </div>
      <div class="stat-badge">
        <span>Framework: <strong>Dart Frog + MongoDB + Redis</strong></span>
      </div>
    </div>
  </header>

  <!-- Quick Jump To Index Section -->
  <section class="jump-section">
    <h2 class="section-title">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="8" y1="6" x2="21" y2="6"></line><line x1="8" y1="12" x2="21" y2="12"></line><line x1="8" y1="18" x2="21" y2="18"></line><line x1="3" y1="6" x2="3.01" y2="6"></line><line x1="3" y1="12" x2="3.01" y2="12"></line><line x1="3" y1="18" x2="3.01" y2="18"></line></svg>
      Quick Jump to API Index (#01 - #${totalCount.toString().padLeft(2, '0')})
    </h2>
    <div class="quick-index-grid" id="quickIndexGrid">
      $quickNavItems
    </div>
  </section>

  <!-- Search & Filter Controls -->
  <div class="controls-bar">
    <div class="search-input-wrapper">
      <svg class="search-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
      <input type="text" class="search-input" id="searchInput" placeholder="Search by path (e.g. /api/user/login), title, index, or keyword..." oninput="handleSearch()">
    </div>
    <div class="filter-chips-row" id="methodFilterRow">
      <span style="font-size:0.75rem; color:var(--text-dim); font-weight:600; text-transform:uppercase;">Method:</span>
      <button class="filter-chip active" onclick="filterMethod('ALL', this)">All</button>
      <button class="filter-chip" onclick="filterMethod('GET', this)">GET</button>
      <button class="filter-chip" onclick="filterMethod('POST', this)">POST</button>
      <button class="filter-chip" onclick="filterMethod('PUT', this)">PUT</button>
      <button class="filter-chip" onclick="filterMethod('DELETE', this)">DELETE</button>
      <button class="filter-chip" onclick="filterMethod('PATCH', this)">PATCH</button>
    </div>
    <div class="filter-chips-row" id="categoryFilterRow">
      <span style="font-size:0.75rem; color:var(--text-dim); font-weight:600; text-transform:uppercase;">Module:</span>
      $categoryFilterChips
    </div>
  </div>

  <!-- API Cards List -->
  <main id="apiCardsContainer">
    $apiCards
  </main>

</div>

<script>
  let selectedMethod = 'ALL';
  let selectedCategory = 'ALL';
  let searchQuery = '';

  function handleSearch() {
    searchQuery = document.getElementById('searchInput').value.toLowerCase().trim();
    applyFilters();
  }

  function filterMethod(method, btn) {
    selectedMethod = method;
    document.querySelectorAll('#methodFilterRow .filter-chip').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    applyFilters();
  }

  function filterCategory(cat, btn) {
    selectedCategory = cat;
    document.querySelectorAll('#categoryFilterRow .filter-chip').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    applyFilters();
  }

  function applyFilters() {
    const cards = document.querySelectorAll('.api-card');
    const navChips = document.querySelectorAll('.nav-chip');

    cards.forEach(card => {
      const cardMethod = card.getAttribute('data-method');
      const cardCategory = card.getAttribute('data-category');
      const cardText = card.getAttribute('data-text').toLowerCase();

      const matchMethod = selectedMethod === 'ALL' || cardMethod === selectedMethod;
      const matchCategory = selectedCategory === 'ALL' || cardCategory === selectedCategory;
      const matchSearch = searchQuery === '' || cardText.includes(searchQuery) || card.id.includes(searchQuery);

      if (matchMethod && matchCategory && matchSearch) {
        card.style.display = 'block';
      } else {
        card.style.display = 'none';
      }
    });

    navChips.forEach(chip => {
      const chipMethod = chip.getAttribute('data-method');
      const chipCategory = chip.getAttribute('data-category');
      const chipText = chip.innerText.toLowerCase();

      const matchMethod = selectedMethod === 'ALL' || chipMethod === selectedMethod;
      const matchCategory = selectedCategory === 'ALL' || chipCategory === selectedCategory;
      const matchSearch = searchQuery === '' || chipText.includes(searchQuery);

      if (matchMethod && matchCategory && matchSearch) {
        chip.style.display = 'flex';
      } else {
        chip.style.display = 'none';
      }
    });
  }

  function copyCurl(btn, id) {
    const code = document.getElementById('curl-' + id).innerText;
    navigator.clipboard.writeText(code).then(() => {
      const origHtml = btn.innerHTML;
      btn.innerHTML = '<span style="color:#34d399;">✓ Copied!</span>';
      setTimeout(() => {
        btn.innerHTML = origHtml;
      }, 2000);
    });
  }
</script>

</body>
</html>
''';
  }
}
