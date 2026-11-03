.pragma library

// Code typing targets. A snippet is deliberately a single line with single
// spaces between tokens: the typing surface splits text on spaces only, so a
// newline or a tab would turn into a broken "word". Everything here is ASCII,
// which also keeps every symbol reachable on a US layout without dead keys.
//
// Keep LANGUAGES in sync with CODE_LANGS in Model.js — the settings validator
// cannot import this file without creating a load-order surprise.

var LANGUAGES = [
  { id: "javascript", label: "JS", name: "JavaScript" },
  { id: "python", label: "Python", name: "Python" },
  { id: "typescript", label: "TS", name: "TypeScript" },
  { id: "shell", label: "Shell", name: "Shell" },
  { id: "css", label: "CSS", name: "CSS" },
  { id: "sql", label: "SQL", name: "SQL" }
]

var SNIPPETS = {
  javascript: [
    'const total = items.reduce((sum, item) => sum + item.price, 0); console.log(total);',
    'function clamp(value, min, max) { return Math.min(Math.max(value, min), max); }',
    'const names = users.filter(u => u.active).map(u => u.name).sort();',
    'if (!cache.has(key)) { cache.set(key, await load(key)); } return cache.get(key);',
    'export class Timer { constructor(ms) { this.ms = ms; } start() { this.id = setTimeout(this.tick, this.ms); } }'
  ],
  python: [
    'def clamp(value, low, high): return max(low, min(value, high))',
    'counts = {word: text.count(word) for word in text.split() if len(word) > 3}',
    'with open(path, "r") as handle: rows = [line.strip() for line in handle]',
    'for index, row in enumerate(rows): print(index, row["name"], row.get("score", 0))',
    'def chunks(items, size): return [items[i:i + size] for i in range(0, len(items), size)]'
  ],
  typescript: [
    'interface Point { x: number; y: number; } const origin: Point = { x: 0, y: 0 };',
    'type Handler = (event: Event) => void; const handlers = new Map<string, Handler>();',
    'function pick<T, K extends keyof T>(obj: T, key: K): T[K] { return obj[key]; }',
    'const state: Readonly<State> = { ...prev, count: prev.count + 1 };',
    'export async function fetchJson<T>(url: string): Promise<T> { const r = await fetch(url); return r.json(); }'
  ],
  shell: [
    'for file in *.log; do gzip -c "$file" > "$file.gz" && rm "$file"; done',
    'find . -name "*.tmp" -type f -mtime +7 -print0 | xargs -0 rm -f',
    'grep -rl "TODO" src | sort | while read -r f; do wc -l "$f"; done',
    'if [ -z "$1" ]; then echo "usage: run <dir>" >&2; exit 1; fi',
    'tar -czf backup.tar.gz -C "$HOME" --exclude=".cache" --exclude="*.iso" Documents'
  ],
  css: [
    '.card { display: flex; gap: 0.5rem; padding: 1rem 1.25rem; border: 1px solid #444; }',
    '@media (min-width: 60rem) { .grid { grid-template-columns: repeat(3, 1fr); } }',
    '.button:hover, .button:focus-visible { outline: 2px solid #7aa2f7; outline-offset: 2px; }',
    ':root { --ink: #a9b1d6; --bg: #1a1b26; --accent: #7aa2f7; --gap: 0.75rem; }',
    '.list > li:nth-child(odd) { background: color-mix(in srgb, var(--ink) 6%, transparent); }'
  ],
  sql: [
    'select id, name, count(*) as runs from sessions group by id, name order by runs desc;',
    'update tasks set done = true, closed_at = now() where id = $1 and owner_id = $2;',
    'select u.name, sum(o.total) as spent from users u join orders o on o.user_id = u.id group by u.name;',
    'create index if not exists orders_user_id_idx on orders (user_id, created_at desc);',
    'with recent as (select * from events where at > now() - interval \'7 days\') select count(*) from recent;'
  ]
}

function languageFor(id) {
  var key = String(id || "")
  for (var i = 0; i < LANGUAGES.length; i++) {
    if (LANGUAGES[i].id === key) return LANGUAGES[i]
  }
  return LANGUAGES[0]
}

// Returns { text, name, id }. The caller shows `name` in the session subtitle,
// so the user can tell a Python run from a Shell run after the fact.
function makeSnippet(id) {
  var lang = languageFor(id)
  var pool = SNIPPETS[lang.id] || SNIPPETS.javascript
  var text = pool[Math.floor(Math.random() * pool.length)]
  return { id: lang.id, name: lang.name, text: text }
}
