/*
 * Mynine exam room renderer — shared by the Android (WebView) and iOS (WKWebView) apps.
 *
 * Renders one PartPayload (docs/desktop/API.md, the same payload the desktop app and the student API send):
 * the passage / task and the sections with their questions, exactly like the web practice room. The native
 * app owns the timer, the number bar, audio and answer sync; this page only shows the part and reports answers.
 *
 * Native → page:  ExamRoom.render(config) · setView('passage'|'questions') · setLayout('phone'|'split')
 *                 setLocked(bool) · setFlagged([questionId]) · scrollToQuestion(questionId) · setFontScale(n)
 * Page → native:  {type:'ready', data:{hasPassage}} · {type:'answer', data:{part_id, question_id, text?|option_ids?}}
 *                 {type:'flag', data:{question_id}} · {type:'log', data:'…'}
 *
 * config: {part, answers: {questionId: {text, option_ids}}, flagged: [ids], locked, view, layout, baseUrl}
 */
(function () {
  'use strict';

  var state = {
    part: null,
    answers: {},
    flagged: {},
    locked: false,
    view: 'questions',
    layout: 'phone',
    baseUrl: '',
    picked: null, // drag and drop: the word picked from the bank
  };

  var STANDARD_LABELS = ['true', 'false', 'not given', 'yes', 'no'];
  var SECTION_BLANK = /\{[^{}\n]*\}/g;
  var EMPTY_BLANK = /\{\}/g;
  var PASSAGE_SLOT = /\{(\d{1,3})\}/g;
  var PASSAGE_ZONE = /\{z\d+:[A-Z]\}/g;
  var MAX_ANSWER = 20000;

  // ---------------------------------------------------------------- bridge

  function send(type, data) {
    var msg = JSON.stringify({ type: type, data: data });
    try {
      if (window.AndroidBridge && window.AndroidBridge.post) {
        window.AndroidBridge.post(msg);
      } else if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.bridge) {
        window.webkit.messageHandlers.bridge.postMessage(msg);
      }
    } catch (e) { /* the page must keep working without a host */ }
  }

  window.onerror = function (message, source, line) {
    send('log', 'JS error: ' + message + ' @' + line);
  };

  // ---------------------------------------------------------------- helpers

  function el(tag, cls, html) {
    var node = document.createElement(tag);
    if (cls) node.className = cls;
    if (html !== undefined && html !== null) node.innerHTML = html;
    return node;
  }

  function escapeHtml(text) {
    return String(text === null || text === undefined ? '' : text)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  function plainText(html) {
    var t = document.createElement('template');
    t.innerHTML = String(html || '');
    return (t.content.textContent || '').replace(/[​-‍﻿]/g, '').replace(/\s+/g, ' ').trim();
  }

  /** Editor HTML is admin-authored and sanitised on the server; strip anything active anyway. */
  function sanitize(html) {
    var t = document.createElement('template');
    t.innerHTML = String(html || '');
    var bad = t.content.querySelectorAll('script,iframe,object,embed,link,meta,style,base,form,frame,frameset');
    for (var i = 0; i < bad.length; i++) bad[i].parentNode.removeChild(bad[i]);
    var all = t.content.querySelectorAll('*');
    for (var j = 0; j < all.length; j++) {
      var node = all[j];
      for (var k = node.attributes.length - 1; k >= 0; k--) {
        var name = node.attributes[k].name.toLowerCase();
        var value = node.attributes[k].value || '';
        if (name.indexOf('on') === 0 || /^\s*javascript:/i.test(value)) node.removeAttribute(node.attributes[k].name);
      }
      if (node.tagName === 'IMG') {
        var src = node.getAttribute('src') || '';
        node.setAttribute('src', absoluteUrl(src));
        node.setAttribute('loading', 'lazy');
      }
      if (node.tagName === 'A') {
        node.removeAttribute('href');
      }
    }
    return t.innerHTML;
  }

  function absoluteUrl(src) {
    src = String(src || '').trim();
    if (!src || /^(https?:|data:)/i.test(src)) return src;
    src = src.replace(/^(\.\.\/)+/, '/');
    if (src.charAt(0) !== '/') src = '/' + src;
    return state.baseUrl.replace(/\/$/, '') + src;
  }

  function answer(questionId) {
    return state.answers[questionId] || { text: null, option_ids: [] };
  }

  function setAnswer(questionId, patch) {
    var current = answer(questionId);
    var next = { text: current.text, option_ids: (current.option_ids || []).slice() };
    if ('text' in patch) next.text = patch.text;
    if ('option_ids' in patch) next.option_ids = patch.option_ids;
    state.answers[questionId] = next;
    var data = { part_id: state.part.id, question_id: questionId };
    if ('text' in patch) data.text = patch.text;
    if ('option_ids' in patch) data.option_ids = patch.option_ids;
    send('answer', data);
  }

  var timers = {};
  function setTextDebounced(questionId, text) {
    state.answers[questionId] = { text: text, option_ids: answer(questionId).option_ids || [] };
    clearTimeout(timers[questionId]);
    timers[questionId] = setTimeout(function () { delete timers[questionId]; setAnswer(questionId, { text: text }); }, 350);
  }

  function badgeLabel(q) {
    var count = q.number_count || 1;
    if (count <= 1) return String(q.number);
    var parts = [];
    for (var i = 0; i < count; i++) parts.push(q.number + i);
    return parts.join('-');
  }

  function badge(q) {
    var b = el('button', 'badge' + (state.flagged[q.id] ? ' flagged' : ''));
    b.type = 'button';
    b.textContent = badgeLabel(q);
    b.setAttribute('aria-label', 'Question ' + q.number + ', flag for review');
    b.dataset.flag = q.id;
    b.addEventListener('click', function () { toggleFlag(q.id); });
    return b;
  }

  function toggleFlag(questionId) {
    if (state.flagged[questionId]) delete state.flagged[questionId]; else state.flagged[questionId] = true;
    send('flag', { question_id: questionId });
    refreshFlags();
  }

  function refreshFlags() {
    var nodes = document.querySelectorAll('[data-flag]');
    for (var i = 0; i < nodes.length; i++) {
      var id = nodes[i].dataset.flag;
      nodes[i].classList.toggle('flagged', !!state.flagged[id]);
    }
  }

  // ---------------------------------------------------------------- ranges (matching)

  function romanToInt(roman) {
    var map = { I: 1, V: 5, X: 10, L: 50, C: 100, D: 500, M: 1000 };
    var s = roman.toUpperCase(), result = 0, prev = 0;
    for (var i = s.length - 1; i >= 0; i--) {
      var cur = map[s[i]] || 0;
      if (cur < prev) result -= cur; else result += cur;
      prev = cur;
    }
    return result;
  }

  function intToRoman(num) {
    var table = [[1000, 'm'], [900, 'cm'], [500, 'd'], [400, 'cd'], [100, 'c'], [90, 'xc'], [50, 'l'], [40, 'xl'], [10, 'x'], [9, 'ix'], [5, 'v'], [4, 'iv'], [1, 'i']];
    var out = '';
    for (var i = 0; i < table.length; i++) {
      while (num >= table[i][0]) { out += table[i][1]; num -= table[i][0]; }
    }
    return out;
  }

  function span(a, b) {
    var out = [], step = a <= b ? 1 : -1;
    for (var i = a; step > 0 ? i <= b : i >= b; i += step) out.push(i);
    return out;
  }

  /** Port of the web buildRange(from, to): numbers, letters, roman numerals or a comma list. */
  function buildRange(fromRaw, toRaw) {
    if (fromRaw === null || toRaw === null || fromRaw === undefined || toRaw === undefined) return [];
    var from = String(fromRaw).trim(), to = String(toRaw).trim();
    if (!from || !to) return [];
    if (/^\d+$/.test(from) && /^\d+$/.test(to)) return span(+from, +to).map(String);
    var romanList = from === 'i' && /^[ivx]$/.test(to);
    if (!romanList && /^[A-Za-z]$/.test(from) && /^[A-Za-z]$/.test(to)) {
      return span(from.toUpperCase().charCodeAt(0), to.toUpperCase().charCodeAt(0)).map(function (c) { return String.fromCharCode(c); });
    }
    if (/^[ivxlcdm]+$/i.test(from) && /^[ivxlcdm]+$/i.test(to)) {
      var a = romanToInt(from), b = romanToInt(to);
      if (a <= 0 || b <= 0) return [];
      var lower = from === from.toLowerCase();
      return span(a, b).map(function (n) { var r = intToRoman(n); return lower ? r : r.toUpperCase(); });
    }
    if (from.indexOf(',') >= 0 && from === to) {
      return from.split(',').map(function (s) { return s.trim().toUpperCase(); }).filter(Boolean);
    }
    return [];
  }

  // ---------------------------------------------------------------- passage

  function questionByNumber(number) {
    var sections = state.part.sections || [];
    for (var i = 0; i < sections.length; i++) {
      var qs = sections[i].questions || [];
      for (var j = 0; j < qs.length; j++) if (qs[j].number === number) return qs[j];
    }
    return null;
  }

  function renderPassage() {
    var pane = document.getElementById('passage');
    pane.innerHTML = '';
    var html = String(state.part.html || '');
    var has = plainText(html) !== '' || /<img/i.test(html);
    document.getElementById('root').classList.toggle('no-passage', !has);
    if (!has) return false;

    html = html.replace(PASSAGE_ZONE, '').replace(PASSAGE_SLOT, function (_, n) {
      return '<span class="slot" data-slot="' + n + '"><b>' + n + '</b><span class="slot-val"></span></span>';
    });
    var body = el('div', 'html', sanitize(html));
    pane.appendChild(body);
    var slots = body.querySelectorAll('.slot');
    for (var i = 0; i < slots.length; i++) {
      (function (slot) {
        slot.addEventListener('click', function () {
          var q = questionByNumber(parseInt(slot.dataset.slot, 10));
          if (q) scrollToQuestion(q.id);
        });
      })(slots[i]);
    }
    refreshSlots();
    return true;
  }

  function refreshSlots() {
    var slots = document.querySelectorAll('.slot');
    for (var i = 0; i < slots.length; i++) {
      var q = questionByNumber(parseInt(slots[i].dataset.slot, 10));
      var text = q ? (answer(q.id).text || '') : '';
      slots[i].querySelector('.slot-val').textContent = text;
      slots[i].classList.toggle('filled', text !== '');
    }
  }

  // ---------------------------------------------------------------- sections

  function renderQuestions() {
    var pane = document.getElementById('questions');
    pane.innerHTML = '';
    var sections = state.part.sections || [];
    if (!sections.length) {
      pane.appendChild(el('div', 'empty', 'No questions in this part.'));
      return;
    }
    sections.forEach(function (section) {
      var box = el('div', 'section');
      box.dataset.section = section.id;
      switch (section.question_type) {
        case 'complete_section': renderCompleteSection(box, section); break;
        case 'drag_and_drop': renderDragDrop(box, section); break;
        case 'essay': renderEssaySection(box, section); break;
        case 'matching': renderMatching(box, section); break;
        default: renderDefault(box, section);
      }
      pane.appendChild(box);
    });
  }

  function instructions(section) {
    if (!plainText(section.html) && !/<img/i.test(section.html || '')) return null;
    return el('div', 'instructions html', sanitize(section.html));
  }

  function gapInput(q, fontEm) {
    var input = document.createElement('input');
    input.type = 'text';
    input.className = 'gap';
    input.autocomplete = 'off';
    input.setAttribute('autocapitalize', 'off');
    input.setAttribute('autocorrect', 'off');
    input.spellcheck = false;
    input.maxLength = MAX_ANSWER;
    input.dataset.q = q.id;
    input.value = answer(q.id).text || '';
    input.disabled = state.locked;
    if (fontEm) input.style.fontSize = fontEm;
    input.addEventListener('input', function () {
      // Several blanks of one question share one answer: keep them in step.
      var same = document.querySelectorAll('input.gap[data-q="' + q.id + '"]');
      for (var i = 0; i < same.length; i++) if (same[i] !== input) same[i].value = input.value;
      setTextDebounced(q.id, input.value);
    });
    input.addEventListener('keydown', function (e) { if (e.key === 'Enter') input.blur(); });
    return input;
  }

  /** Replace the n-th blank marker of html with nodes made by make(index); returns a container. */
  function withBlanks(html, pattern, make) {
    var index = 0;
    var marked = String(html || '').replace(pattern, function () { return '<span data-blank="' + (index++) + '"></span>'; });
    var container = el('div', 'html', sanitize(marked));
    var holes = container.querySelectorAll('[data-blank]');
    for (var i = 0; i < holes.length; i++) {
      var node = make(parseInt(holes[i].dataset.blank, 10));
      if (node) holes[i].parentNode.replaceChild(node, holes[i]); else holes[i].parentNode.removeChild(holes[i]);
    }
    return container;
  }

  function renderCompleteSection(box, section) {
    box.appendChild(withBlanks(section.html, SECTION_BLANK, function (i) {
      var q = section.questions[i];
      if (!q) return null;
      var wrap = el('span', 'gapwrap');
      wrap.id = 'q-' + q.id;
      var num = el('b', 'gapnum', escapeHtml(q.number) + '.');
      num.dataset.flag = q.id;
      num.addEventListener('click', function () { toggleFlag(q.id); });
      wrap.appendChild(num);
      wrap.appendChild(gapInput(q));
      return wrap;
    }));
  }

  function renderDragDrop(box, section) {
    box.appendChild(withBlanks(section.html, SECTION_BLANK, function (i) {
      var q = section.questions[i];
      if (!q) return null;
      var drop = el('span', 'drop');
      drop.id = 'q-' + q.id;
      drop.dataset.drop = q.id;
      drop.addEventListener('click', function (e) {
        if (state.locked) return;
        if (e.target.classList.contains('clear')) {
          setAnswer(q.id, { text: '' });
        } else if (state.picked !== null) {
          setAnswer(q.id, { text: state.picked });
          state.picked = null;
        } else {
          return;
        }
        refreshDragDrop(section, box);
      });
      return drop;
    }));
    var bank = el('div', 'bank');
    bank.dataset.bank = section.id;
    box.appendChild(bank);
    refreshDragDrop(section, box);
  }

  /** root: the section element (it may not be in the document yet while the part renders). */
  function refreshDragDrop(section, root) {
    var norm = function (s) { return String(s || '').trim().toLowerCase(); };
    var available = (section.drag_options || []).map(function (o) { return String(o.label).trim(); });
    section.questions.forEach(function (q) {
      var drop = root.querySelector('[data-drop="' + q.id + '"]');
      var value = answer(q.id).text || '';
      if (value) {
        var idx = -1;
        for (var i = 0; i < available.length; i++) if (norm(available[i]) === norm(value)) { idx = i; break; }
        if (idx >= 0) available.splice(idx, 1);
      }
      if (!drop) return;
      drop.className = 'drop' + (value ? ' filled' : '') + (!value && state.picked !== null ? ' target' : '');
      drop.innerHTML = '<b data-flag="' + q.id + '">' + escapeHtml(q.number) + '</b>' +
        (value ? '<span>' + escapeHtml(value) + '</span>' + (state.locked ? '' : '<span class="clear" aria-label="Remove">×</span>') : '');
    });
    var bank = root.querySelector('[data-bank="' + section.id + '"]');
    if (!bank) return;
    bank.innerHTML = '';
    available.forEach(function (label) {
      var chip = el('button', 'chip' + (state.picked === label ? ' picked' : ''));
      chip.type = 'button';
      chip.textContent = label;
      chip.disabled = state.locked;
      chip.addEventListener('click', function () {
        state.picked = state.picked === label ? null : label;
        refreshDragDrop(section, root);
      });
      bank.appendChild(chip);
    });
    refreshFlags();
  }

  function renderMatching(box, section) {
    var ins = instructions(section);
    if (ins) box.appendChild(ins);
    var hasTexts = (section.options || []).length > 0;
    var headings = hasTexts
      ? section.options.map(function (o) { return plainText(o.html); })
      : buildRange(section.from_option, section.to_option);

    if (hasTexts && !/list of/i.test(section.html || '')) {
      var list = el('div', 'list-box');
      list.appendChild(el('div', 'title', 'LIST OF HEADINGS'));
      headings.forEach(function (h) { list.appendChild(el('div', 'item', escapeHtml(h))); });
      box.appendChild(list);
    }

    section.questions.forEach(function (q) {
      var row = el('div', 'match-row');
      row.id = 'q-' + q.id;
      row.appendChild(badge(q));
      var title = plainText(q.html);
      row.appendChild(el('div', 'title', escapeHtml(title || ('Section / Paragraph ' + q.number))));
      var select = document.createElement('select');
      select.className = 'match' + (hasTexts ? ' wide' : '');
      select.disabled = state.locked;
      select.setAttribute('aria-label', 'Answer for question ' + q.number);
      var current = answer(q.id).text || '';
      var options = headings.slice();
      if (current && options.indexOf(current) < 0) options.push(current);
      select.appendChild(new Option('–', ''));
      options.forEach(function (h) { select.appendChild(new Option(h, h, false, h === current)); });
      select.value = current;
      select.addEventListener('change', function () {
        setAnswer(q.id, { text: select.value });
        refreshSlots();
      });
      row.appendChild(select);
      box.appendChild(row);
    });
  }

  function renderEssaySection(box, section) {
    var partHtml = state.part.html || '';
    var taskInPassage = plainText(partHtml) !== '' || /<img/i.test(partHtml);
    if (!taskInPassage) {
      var ins = instructions(section);
      if (ins) box.appendChild(ins);
    }
    section.questions.forEach(function (q) {
      var wrap = el('div', 'essay');
      wrap.id = 'q-' + q.id;
      var head = el('div', 'question');
      head.appendChild(badge(q));
      var body = el('div', 'body');
      if (!taskInPassage && plainText(q.html)) body.appendChild(el('div', 'qtext html', sanitize(q.html)));
      head.appendChild(body);
      wrap.appendChild(head);

      var text = (plainText(q.html) + ' ' + plainText(section.html)).toLowerCase();
      var target = state.part.order === 1 || text.indexOf('task 1') >= 0 ? 150 : 250;
      var progress = el('div', 'progress');
      progress.innerHTML = '<div class="row"><span>WRITING PROGRESS</span><span class="count"></span></div><div class="bar"><i></i></div>';
      var area = document.createElement('textarea');
      area.value = answer(q.id).text || '';
      area.disabled = state.locked;
      area.maxLength = MAX_ANSWER;
      area.setAttribute('autocapitalize', 'sentences');
      area.placeholder = 'Start writing your answer here…';

      var update = function () {
        var t = area.value.trim();
        var words = t ? t.split(/\s+/).length : 0;
        var percent = Math.min(100, Math.round((words / target) * 100));
        progress.querySelector('.count').textContent = words + ' / ' + target + ' words';
        var bar = progress.querySelector('i');
        bar.style.width = percent + '%';
        bar.className = words >= target ? 'met' : (percent > 60 ? 'mid' : '');
      };
      area.addEventListener('input', function () { update(); setTextDebounced(q.id, area.value); });
      update();
      wrap.appendChild(progress);
      wrap.appendChild(area);
      box.appendChild(wrap);
    });
  }

  function renderDefault(box, section) {
    var ins = instructions(section);
    if (ins) box.appendChild(ins);
    var type = section.question_type;
    var showOptions = ['fill_blank', 'matching', 'essay', 'complete_section'].indexOf(type) < 0;
    var multi = type === 'multiple_response' || section.input_type === 'checkbox';

    section.questions.forEach(function (q) {
      var row = el('div', 'question');
      row.id = 'q-' + q.id;
      row.appendChild(badge(q));
      var body = el('div', 'body');
      var blanks = (String(q.html || '').match(EMPTY_BLANK) || []).length;
      var text = withBlanks(q.html, EMPTY_BLANK, function () { return gapInput(q); });
      text.classList.add('qtext');
      body.appendChild(text);
      if (type === 'fill_blank' && blanks === 0) body.appendChild(gapInput(q));

      if (showOptions && (q.options || []).length) {
        var opts = el('div', 'options');
        opts.dataset.options = q.id;
        body.appendChild(opts);
        renderOptions(opts, q, multi);
      }
      row.appendChild(body);
      box.appendChild(row);
    });
  }

  function renderOptions(container, q, multi) {
    container.innerHTML = '';
    var selected = (answer(q.id).option_ids || []).map(Number);
    var limit = multi ? Math.max(1, q.number_count || 1) : 1;
    q.options.forEach(function (o, i) {
      var text = plainText(o.html);
      var checked = selected.indexOf(o.id) >= 0;
      var disabled = state.locked || (multi && !checked && selected.length >= limit);
      var standard = STANDARD_LABELS.indexOf(text.toLowerCase()) >= 0;
      var row = el('div', 'option' + (checked ? ' checked' : '') + (disabled && !checked ? ' disabled' : ''));
      row.setAttribute('role', multi ? 'checkbox' : 'radio');
      row.setAttribute('aria-checked', checked ? 'true' : 'false');
      row.tabIndex = 0;
      row.innerHTML = '<span class="mark ' + (multi ? 'box' : 'radio') + '"></span><span>' +
        (standard ? '' : '<b>' + String.fromCharCode(65 + i) + ')</b> ') + escapeHtml(text.toUpperCase()) + '</span>';
      row.addEventListener('click', function () {
        if (state.locked || (disabled && !checked)) return;
        var current = (answer(q.id).option_ids || []).map(Number);
        var next;
        if (multi) {
          next = checked ? current.filter(function (id) { return id !== o.id; }) : (current.length < limit ? current.concat([o.id]) : current);
        } else {
          next = [o.id];
        }
        setAnswer(q.id, { option_ids: next });
        renderOptions(container, q, multi);
      });
      container.appendChild(row);
    });
  }

  // ---------------------------------------------------------------- public API

  function applyClasses() {
    var root = document.getElementById('root');
    root.classList.toggle('layout-phone', state.layout !== 'split');
    root.classList.toggle('layout-split', state.layout === 'split');
    root.classList.toggle('view-passage', state.view === 'passage');
    root.classList.toggle('view-questions', state.view !== 'passage');
  }

  function scrollToQuestion(questionId) {
    var node = document.getElementById('q-' + questionId);
    if (!node) return;
    if (state.layout !== 'split' && state.view !== 'questions') {
      state.view = 'questions';
      applyClasses();
    }
    node.scrollIntoView({ block: 'center', behavior: 'smooth' });
    node.classList.remove('flash');
    void node.offsetWidth;
    node.classList.add('flash');
  }

  window.ExamRoom = {
    render: function (config) {
      state.part = config.part;
      state.answers = {};
      var answers = config.answers || {};
      Object.keys(answers).forEach(function (k) { state.answers[k] = answers[k]; });
      (state.part.sections || []).forEach(function (s) {
        (s.questions || []).forEach(function (q) {
          if (!state.answers[q.id] && q.answer && (q.answer.text !== null || (q.answer.option_ids || []).length)) {
            state.answers[q.id] = { text: q.answer.text, option_ids: q.answer.option_ids || [] };
          }
        });
      });
      state.flagged = {};
      (config.flagged || []).forEach(function (id) { state.flagged[id] = true; });
      state.locked = !!config.locked;
      state.view = config.view || 'questions';
      state.layout = config.layout || 'phone';
      state.baseUrl = config.baseUrl || '';
      state.picked = null;
      applyClasses();
      var hasPassage = renderPassage();
      renderQuestions();
      refreshFlags();
      document.getElementById('passage').scrollTop = 0;
      document.getElementById('questions').scrollTop = 0;
      send('ready', { hasPassage: hasPassage, part_id: state.part.id });
    },
    setView: function (view) { state.view = view; applyClasses(); },
    setLayout: function (layout) { state.layout = layout; applyClasses(); },
    setLocked: function (locked) {
      state.locked = !!locked;
      var inputs = document.querySelectorAll('input, textarea, select, .chip');
      for (var i = 0; i < inputs.length; i++) inputs[i].disabled = state.locked;
      if (state.locked) document.body.classList.add('locked');
    },
    setFlagged: function (ids) {
      state.flagged = {};
      (ids || []).forEach(function (id) { state.flagged[id] = true; });
      refreshFlags();
    },
    scrollToQuestion: scrollToQuestion,
    setFontScale: function (scale) { document.documentElement.style.setProperty('--font-scale', String(scale || 1)); },
    /** Flush debounced text answers now (before the module is submitted or the app goes to the background). */
    flush: function () {
      Object.keys(timers).forEach(function (id) {
        clearTimeout(timers[id]);
        delete timers[id];
        setAnswer(parseInt(id, 10), { text: answer(id).text });
      });
    },
  };

  send('loaded', {});
})();
